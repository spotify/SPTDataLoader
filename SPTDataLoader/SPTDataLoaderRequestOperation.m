#import "SPTDataLoaderRequestOperation.h"

#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTExpTime.h>

#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTDataLoaderRateLimiter.h"
#import "SPTDataLoaderResponse+Private.h"

@interface SPTDataLoaderRequestOperation () <NSURLSessionTaskDelegate>

@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;

@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong) SPTDataLoaderResponse *response;
@property (nonatomic, strong) SPTExpTime *expTime;
@property (nonatomic, assign) CFAbsoluteTime absoluteStartTime;

@property (atomic, assign) BOOL isFinished;
@property (atomic, assign) BOOL isExecuting;

@end

@implementation SPTDataLoaderRequestOperation

#pragma mark SPTDataLoaderRequestOperation

+ (instancetype)dataLoaderRequestOperationWithRequest:(SPTDataLoaderRequest *)request
                                                 task:(NSURLSessionTask *)task
                               requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                          rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter
{
    return [[self alloc] initWithRequest:request
                                    task:task
                  requestResponseHandler:requestResponseHandler
                             rateLimiter:rateLimiter];
}

- (instancetype)initWithRequest:(SPTDataLoaderRequest *)request
                           task:(NSURLSessionTask *)task
         requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                    rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _request = request;
    _task = task;
    _requestResponseHandler = requestResponseHandler;
    _rateLimiter = rateLimiter;
    
    _expTime = [SPTExpTime expTimeWithInitialTime:1.0 maxTime:60.0 * 60.0];
    
    return self;
}

- (void)receiveData:(NSData *)data
{
    [self.requestResponseHandler receivedDataChunk:data forResponse:self.response];
    [self.receivedData appendData:data];
}

- (void)completeWithError:(NSError *)error
{
    self.isExecuting = NO;
    self.isFinished = YES;
    
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
            if (self.retryCount++ != self.request.retryCount) {
                [self start];
                return;
            }
        }
        [self.requestResponseHandler failedResponse:self.response];
        return;
    }
    
    [self.requestResponseHandler successfulResponse:self.response];
}

- (NSURLSessionResponseDisposition)receiveResponse:(NSURLResponse *)response
{
    if (self.isCancelled) {
        return NSURLSessionResponseCancel;
    }
    
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:response];
    [self.requestResponseHandler receivedInitialResponse:self.response];
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.expectedContentLength > 0) {
            self.receivedData = [NSMutableData dataWithCapacity:httpResponse.expectedContentLength];
        } else {
            self.receivedData = [NSMutableData data];
        }
    }
    
    return NSURLSessionResponseAllow;
}

- (void)checkRateLimiterAndExecute
{
    if (self.isCancelled) {
        return;
    }
    
    NSTimeInterval waitTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:self.request];
    if (!waitTime) {
        [self checkRetryLimiterAndExecute];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^ {
            [self checkRateLimiterAndExecute];
        });
    }
}

- (void)checkRetryLimiterAndExecute
{
    if (self.isCancelled) {
        return;
    }
    
    NSTimeInterval waitTime = self.expTime.timeIntervalAndCalculateNext;
    if (!waitTime) {
        self.isExecuting = YES;
        self.isFinished = NO;
        
        self.absoluteStartTime = CFAbsoluteTimeGetCurrent();
        [self.task resume];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^ {
            [self checkRateLimiterAndExecute];
        });
    }
}

#pragma mark NSOperationQueue

- (void)start
{
    if (self.isCancelled) {
        self.isFinished = YES;
        self.isExecuting = NO;
        return;
    }
    
    [self checkRateLimiterAndExecute];
}

- (void)cancel
{
    [self.requestResponseHandler cancelledRequest:self.request];
    [self.task cancel];
    self.isExecuting = NO;
    
    [super cancel];
}

- (BOOL)isConcurrent
{
    return YES;
}

#pragma mark NSKeyValueObserving

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *) key
{
    return YES;
}

@end
