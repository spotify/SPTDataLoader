#import "SPTDataLoaderService.h"

#import "SPTDataLoaderFactory+Private.h"
#import "SPTCancellationTokenFactoryImplementation.h"
#import "SPTCancellationToken.h"
#import "SPTDataLoaderRequestOperation.h"
#import "SPTDataLoaderRequest+Private.h"
#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderRateLimiter.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTDataLoaderResolver.h"

@interface SPTDataLoaderService () <SPTDataLoaderRequestResponseHandlerDelegate, SPTCancellationTokenDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) id<SPTCancellationTokenFactory> cancellationTokenFactory;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionQueue;
@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, strong) SPTDataLoaderResolver *resolver;

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
    _rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:10.0];
    _resolver = [SPTDataLoaderResolver new];
    
    return self;
}

- (SPTDataLoaderFactory *)createDataLoaderFactoryWithAuthorisers:(NSArray *)authorisers
{
    return [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:self authorisers:authorisers];
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

- (void)performRequest:(SPTDataLoaderRequest *)request
requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
{
    NSString *host = [self.resolver addressForHost:request.URL.host];
    if (![host isEqualToString:request.URL.host]) {
        NSURLComponents *requestComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:nil];
        requestComponents.host = host;
        request.URL = requestComponents.URL;
    }
    
    NSURLRequest *urlRequest = request.urlRequest;
    NSURLSessionTask *task = [self.session dataTaskWithRequest:urlRequest];
    SPTDataLoaderRequestOperation *operation = [SPTDataLoaderRequestOperation dataLoaderRequestOperationWithRequest:request
                                                                                                               task:task
                                                                                             requestResponseHandler:requestResponseHandler
                                                                                                        rateLimiter:self.rateLimiter];
    [self.sessionQueue addOperation:operation];
}

#pragma mark SPTDataLoaderRequestResponseHandlerDelegate

- (id<SPTCancellationToken>)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                    performRequest:(SPTDataLoaderRequest *)request
{
    request.cancellationToken = [self.cancellationTokenFactory createCancellationTokenWithDelegate:self];
    
    if ([requestResponseHandler respondsToSelector:@selector(shouldAuthoriseRequest:)]) {
        if ([requestResponseHandler shouldAuthoriseRequest:request]) {
            if ([requestResponseHandler respondsToSelector:@selector(authoriseRequest:)]) {
                [requestResponseHandler authoriseRequest:request];
                return request.cancellationToken;
            }
        }
    }
    
    [self performRequest:request requestResponseHandler:requestResponseHandler];
    return request.cancellationToken;
}

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
             authorisedRequest:(SPTDataLoaderRequest *)request
{
    [self performRequest:request requestResponseHandler:requestResponseHandler];
}

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
      failedToAuthoriseRequest:(SPTDataLoaderRequest *)request
                         error:(NSError *)error
{
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    response.error = error;
    [requestResponseHandler failedResponse:response];
}

#pragma mark SPTCancellationTokenDelegate

- (void)cancellationTokenDidCancel:(id<SPTCancellationToken>)cancellationToken
{
    for (SPTDataLoaderRequestOperation *operation in self.sessionQueue.operations) {
        if ([operation.request.cancellationToken isEqual:cancellationToken]) {
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

@end
