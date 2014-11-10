#import "SPTDataLoaderService.h"

#import "SPTDataLoaderFactory+Private.h"
#import "SPTCancellationTokenFactoryImplementation.h"
#import "SPTCancellationToken.h"
#import "SPTDataLoaderRequestOperation.h"
#import "SPTDataLoaderRequest+Private.h"
#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTExpTime.h"

@interface SPTDataLoaderService () <SPTDataLoaderRequestResponseHandlerDelegate, SPTCancellationTokenDelegate, NSURLSessionDataDelegate, SPTDataLoaderRequestOperationDelegate>

@property (nonatomic, strong) id<SPTCancellationTokenFactory> cancellationTokenFactory;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionQueue;

@property (nonatomic, strong) NSMutableDictionary *serviceRetryTimes;

@end

@implementation SPTDataLoaderService

#pragma mark SPTDataLoaderService

+ (instancetype)dataLoaderServiceWithUserAgent:(NSString *)userAgent
{
    return [[self alloc] initWithUserAgent:userAgent];
}

- (instancetype)initWithUserAgent:(NSString *)userAgent
{
    const NSTimeInterval SPTDataLoaderServiceTimeoutInterval = 20.0;
    
    NSString * const SPTDataLoaderServiceUserAgentHeader = @"User-Agent";
    
    if (!(self = [super init])) {
        return nil;
    }
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = SPTDataLoaderServiceTimeoutInterval;
    configuration.timeoutIntervalForResource = SPTDataLoaderServiceTimeoutInterval;
    configuration.HTTPShouldUsePipelining = YES;
    if (userAgent) {
        configuration.HTTPAdditionalHeaders = @{ SPTDataLoaderServiceUserAgentHeader : userAgent };
    }
    
    _cancellationTokenFactory = [SPTCancellationTokenFactoryImplementation new];
    _sessionQueue = [NSOperationQueue new];
    _sessionQueue.maxConcurrentOperationCount = 1;
    _sessionQueue.name = NSStringFromClass(self.class);
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_sessionQueue];
    _serviceRetryTimes = [NSMutableDictionary new];
    
    return self;
}

- (SPTDataLoaderFactory *)createDataLoaderFactory
{
    return [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:self];
}

- (SPTDataLoaderRequestOperation *)operationForTask:(NSURLSessionTask *)task
{
    for (SPTDataLoaderRequestOperation *operation in self.sessionQueue.operations) {
        if ([operation.task isEqual:task]) {
            return operation;
        }
    }
    
    return nil;
}

#pragma mark SPTDataLoaderRequestResponseHandlerDelegate

- (id<SPTCancellationToken>)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                    performRequest:(SPTDataLoaderRequest *)request
{
    NSURLRequest *urlRequest = request.urlRequest;
    NSURLSessionTask *task = [self.session dataTaskWithRequest:urlRequest];
    id<SPTCancellationToken> cancellationToken = [self.cancellationTokenFactory createCancellationTokenWithDelegate:self];
    SPTDataLoaderRequestOperation *operation = [SPTDataLoaderRequestOperation dataLoaderRequestOperationWithRequest:request
                                                                                                               task:task
                                                                                                  cancellationToken:cancellationToken];
    [self.sessionQueue addOperation:operation];
    return cancellationToken;
}

#pragma mark SPTCancellationTokenDelegate

- (void)cancellationTokenDidCancel:(id<SPTCancellationToken>)cancellationToken
{
    for (SPTDataLoaderRequestOperation *operation in self.sessionQueue.operations) {
        if ([operation.cancellationToken isEqual:cancellationToken]) {
            [operation cancel];
            break;
        }
    }
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    SPTDataLoaderRequestOperation *operation = [self operationForTask:dataTask];
    completionHandler([operation receiveResponse:response]);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    // This is highly unusual
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    SPTDataLoaderRequestOperation *operation = [self operationForTask:dataTask];
    [operation receiveData:data];
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    SPTDataLoaderRequestOperation *operation = [self operationForTask:task];
    [operation completeWithError:error];
}

#pragma mark SPTDataLoaderRequestOperationDelegate

- (NSTimeInterval)dataLoaderRequestOperation:(SPTDataLoaderRequestOperation *)requestOperation
                timeLeftUntilExecutionForURL:(NSURL *)URL
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:nil];
    SPTExpTime *expTime = self.serviceRetryTimes[components.path.pathComponents.firstObject];
    return expTime.timeInterval;
}

@end
