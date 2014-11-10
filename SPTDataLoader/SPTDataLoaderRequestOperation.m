#import "SPTDataLoaderRequestOperation.h"

#import "SPTCancellationToken.h"

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
    
    self.isExecuting = YES;
    self.isFinished = NO;
    
    [self.task resume];
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
