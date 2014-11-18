#import "SPTDataLoaderRequestTaskHandler.h"

#import <SPTDataLoader/SPTDataLoaderResponse.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>

#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTExpTime.h"

@interface SPTDataLoaderRequestTaskHandler ()

@property (nonatomic, weak) id<SPTDataLoaderRequestResponseHandler> requestResponseHandler;
@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;

@property (nonatomic, strong) SPTDataLoaderResponse *response;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, assign) CFAbsoluteTime absoluteStartTime;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, copy) dispatch_block_t executionBlock;
@property (nonatomic, strong) SPTExpTime *expTime;

@property (nonatomic, assign) BOOL calledSuccessfulResponse;
@property (nonatomic, assign) BOOL calledFailedResponse;
@property (nonatomic, assign) BOOL calledCancelledRequest;
@property (nonatomic, assign) BOOL started;

@end

@implementation SPTDataLoaderRequestTaskHandler

#pragma mark SPTDataLoaderRequestTaskHandler

+ (instancetype)dataLoaderRequestTaskHandlerWithTask:(NSURLSessionTask *)task
                                             request:(SPTDataLoaderRequest *)request
                              requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                         rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter
{
    return [[self alloc] initWithTask:task
                              request:request
               requestResponseHandler:requestResponseHandler
                          rateLimiter:rateLimiter];
}

- (instancetype)initWithTask:(NSURLSessionTask *)task
                     request:(SPTDataLoaderRequest *)request
      requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                 rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter
{
    const NSTimeInterval SPTDataLoaderRequestTaskHandlerMaximumTime = 60.0;
    
    if (!(self = [super init])) {
        return nil;
    }
    
    _task = task;
    _request = request;
    _requestResponseHandler = requestResponseHandler;
    _rateLimiter = rateLimiter;
    
    __weak __typeof(self) weakSelf = self;
    _executionBlock = ^ {
        [weakSelf checkRateLimiterAndExecute];
    };
    _expTime = [SPTExpTime expTimeWithInitialTime:0.0 maxTime:SPTDataLoaderRequestTaskHandlerMaximumTime];
    
    return self;
}

- (void)receiveData:(NSData *)data
{
    if (self.request.chunks) {
        [self.requestResponseHandler receivedDataChunk:data forResponse:self.response];
    } else {
        [self.receivedData appendData:data];
    }
}

- (void)completeWithError:(NSError *)error
{
    if ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled) {
        [self.requestResponseHandler cancelledRequest:self.request];
        self.calledCancelledRequest = YES;
        return;
    }
    
    [self.rateLimiter executedRequest:self.request];
    
    if (error) {
        self.response.error = error;
    }
    
    self.response.body = self.receivedData;
    self.response.requestTime = CFAbsoluteTimeGetCurrent() - self.absoluteStartTime;
    
    if (self.response.retryAfter) {
        [self.rateLimiter setRetryAfter:self.response.retryAfter.timeIntervalSinceReferenceDate
                                 forURL:self.response.request.URL];
    }
    
    if (self.response.error) {
        if ([self.response shouldRetry]) {
            if (self.retryCount++ != self.request.maximumRetryCount) {
                [self start];
                return;
            }
        }
        [self.requestResponseHandler failedResponse:self.response];
        self.calledFailedResponse = YES;
        return;
    }
    
    [self.requestResponseHandler successfulResponse:self.response];
    self.calledSuccessfulResponse = YES;
}

- (NSURLSessionResponseDisposition)receiveResponse:(NSURLResponse *)response
{
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:response];
    [self.requestResponseHandler receivedInitialResponse:self.response];
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.expectedContentLength > 0) {
            self.receivedData = [NSMutableData dataWithCapacity:httpResponse.expectedContentLength];
        }
    }
    
    if (!self.receivedData) {
        self.receivedData = [NSMutableData data];
    }
    
    return NSURLSessionResponseAllow;
}

- (void)start
{
    self.started = YES;
    self.executionBlock();
}

- (void)checkRateLimiterAndExecute
{
    NSTimeInterval waitTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:self.request];
    if (waitTime == 0.0) {
        [self checkRetryLimiterAndExecute];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), self.executionBlock);
    }
}

- (void)checkRetryLimiterAndExecute
{
    NSTimeInterval waitTime = self.expTime.timeIntervalAndCalculateNext;
    if (waitTime == 0.0) {
        self.absoluteStartTime = CFAbsoluteTimeGetCurrent();
        [self.task resume];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), self.executionBlock);
    }
}

#pragma mark NSObject

- (void)dealloc
{
    if (_started) {
        NSAssert(_calledCancelledRequest || _calledFailedResponse || _calledSuccessfulResponse, @"A started task was not ended with a call to either its cancel, failed or success callbacks");
    }
}

@end
