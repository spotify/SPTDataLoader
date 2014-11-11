#import "SPTDataLoaderRequestOperation.h"

#import "SPTCancellationToken.h"
#import "SPTDataLoaderRequest.h"
#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderResponse+Private.h"

@interface SPTDataLoaderRequestOperation () <NSURLSessionTaskDelegate>

@property (nonatomic, strong) SPTDataLoaderRequest *request;

@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic, assign) NSUInteger retryCount;

@property (atomic, assign) BOOL isFinished;
@property (atomic, assign) BOOL isExecuting;

@end

@implementation SPTDataLoaderRequestOperation

#pragma mark SPTDataLoaderRequestOperation

+ (instancetype)dataLoaderRequestOperationWithRequest:(SPTDataLoaderRequest *)request
                                                 task:(NSURLSessionTask *)task
                                    cancellationToken:(id<SPTCancellationToken>)cancellationToken
                               requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
{
    return [[self alloc] initWithRequest:request
                                    task:task
                       cancellationToken:cancellationToken
                  requestResponseHandler:requestResponseHandler];
}

- (instancetype)initWithRequest:(SPTDataLoaderRequest *)request
                           task:(NSURLSessionTask *)task
              cancellationToken:(id<SPTCancellationToken>)cancellationToken
         requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _request = request;
    _task = task;
    _cancellationToken = cancellationToken;
    _requestResponseHandler = requestResponseHandler;
    
    return self;
}

- (void)receiveData:(NSData *)data
{
    [self.receivedData appendData:data];
}

- (void)completeWithError:(NSError *)error
{
    self.isExecuting = NO;
    self.isFinished = YES;
    
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request];
    if (error) {
        if (self.retryCount++ != self.request.retryCount) {
            [self start];
        } else {
            [self.requestResponseHandler failedResponse:response];
        }
    } else {
        [self.requestResponseHandler successfulResponse:response];
    }
}

- (NSURLSessionResponseDisposition)receiveResponse:(NSURLResponse *)response
{
    if (self.isCancelled) {
        return NSURLSessionResponseCancel;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (httpResponse.expectedContentLength) {
        self.receivedData = [NSMutableData dataWithCapacity:httpResponse.expectedContentLength];
    } else {
        self.receivedData = [NSMutableData data];
    }
    
    return NSURLSessionResponseAllow;
}

#pragma mark NSOperationQueue

- (void)start
{
    if (self.isCancelled) {
        self.isFinished = YES;
        self.isExecuting = NO;
        return;
    }
    
    dispatch_block_t executionBlock = ^ {
        self.isExecuting = YES;
        self.isFinished = NO;
        
        [self.task resume];
    };
    
    NSTimeInterval waitTime = [self.delegate dataLoaderRequestOperation:self
                                           timeLeftUntilExecutionForURL:self.request.URL];
    if (!waitTime) {
        executionBlock();
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)),
                       dispatch_get_main_queue(),
                       executionBlock);
    }
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
