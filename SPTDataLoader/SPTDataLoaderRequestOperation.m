#import "SPTDataLoaderRequestOperation.h"

#import "SPTCancellationToken.h"
#import "SPTDataLoaderRequest.h"

@interface SPTDataLoaderRequestOperation () <NSURLSessionTaskDelegate>

@property (nonatomic, strong) SPTDataLoaderRequest *request;

@property (nonatomic, strong) NSMutableData *receivedData;

@property (atomic, assign) BOOL isFinished;
@property (atomic, assign) BOOL isExecuting;

@end

@implementation SPTDataLoaderRequestOperation

#pragma mark SPTDataLoaderRequestOperation

+ (instancetype)dataLoaderRequestOperationWithRequest:(SPTDataLoaderRequest *)request
                                                 task:(NSURLSessionTask *)task
                                    cancellationToken:(id<SPTCancellationToken>)cancellationToken
{
    return [[self alloc] initWithRequest:request task:task cancellationToken:cancellationToken];
}

- (instancetype)initWithRequest:(SPTDataLoaderRequest *)request
                           task:(NSURLSessionTask *)task
              cancellationToken:(id<SPTCancellationToken>)cancellationToken
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _request = request;
    _task = task;
    _cancellationToken = cancellationToken;
    
    _receivedData = [NSMutableData data];
    
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
}

- (NSURLSessionResponseDisposition)receiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    
    if (httpResponse.expectedContentLength) {
        self.receivedData = [NSMutableData dataWithCapacity:httpResponse.expectedContentLength];
    } else {
        self.receivedData = [NSMutableData data];
    }
    
    return self.isCancelled ? NSURLSessionResponseCancel : NSURLSessionResponseAllow;
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
