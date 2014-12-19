#import <SPTDataLoader/SPTDataLoaderService.h>

#import <SPTDataLoader/SPTCancellationTokenFactoryImplementation.h>
#import <SPTDataLoader/SPTCancellationToken.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>
#import <SPTDataLoader/SPTDataLoaderResolver.h>
#import <SPTDataLoader/SPTDataLoaderConsumptionObserver.h>

#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoaderRequest+Private.h"
#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTDataLoaderRequestTaskHandler.h"

@interface SPTDataLoaderService () <SPTDataLoaderRequestResponseHandlerDelegate, SPTCancellationTokenDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, strong) SPTDataLoaderResolver *resolver;

@property (nonatomic, strong) id<SPTCancellationTokenFactory> cancellationTokenFactory;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *sessionQueue;
@property (nonatomic, strong) NSMutableArray *handlers;
@property (nonatomic, strong) NSMapTable *consumptionObservers;

@end

@implementation SPTDataLoaderService

#pragma mark SPTDataLoaderService

+ (instancetype)dataLoaderServiceWithUserAgent:(NSString *)userAgent
                                   rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter
                                      resolver:(SPTDataLoaderResolver *)resolver
{
    return [[self alloc] initWithUserAgent:userAgent rateLimiter:rateLimiter resolver:resolver];
}

- (instancetype)initWithUserAgent:(NSString *)userAgent
                      rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter
                         resolver:(SPTDataLoaderResolver *)resolver
{
    const NSTimeInterval SPTDataLoaderServiceTimeoutInterval = 20.0;
    const NSUInteger SPTDataLoaderServiceMaxConcurrentOperations = 32;
    
    NSString * const SPTDataLoaderServiceUserAgentHeader = @"User-Agent";
    
    if (!(self = [super init])) {
        return nil;
    }
    
    _rateLimiter = rateLimiter;
    _resolver = resolver;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = SPTDataLoaderServiceTimeoutInterval;
    configuration.timeoutIntervalForResource = SPTDataLoaderServiceTimeoutInterval;
    configuration.HTTPShouldUsePipelining = YES;
    if (userAgent) {
        configuration.HTTPAdditionalHeaders = @{ SPTDataLoaderServiceUserAgentHeader : userAgent };
    }
    
    _cancellationTokenFactory = [SPTCancellationTokenFactoryImplementation new];
    _sessionQueue = [NSOperationQueue new];
    _sessionQueue.maxConcurrentOperationCount = SPTDataLoaderServiceMaxConcurrentOperations;
    _sessionQueue.name = NSStringFromClass(self.class);
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_sessionQueue];
    _handlers = [NSMutableArray new];
    _consumptionObservers = [NSMapTable weakToStrongObjectsMapTable];
    
    return self;
}

- (SPTDataLoaderFactory *)createDataLoaderFactoryWithAuthorisers:(NSArray *)authorisers
{
    return [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:self authorisers:authorisers];
}

- (void)addConsumptionObserver:(id<SPTDataLoaderConsumptionObserver>)consumptionObserver on:(dispatch_queue_t)queue
{
    if (consumptionObserver && queue) {
        @synchronized(self.consumptionObservers) {
            [self.consumptionObservers setObject:queue forKey:consumptionObserver];
        }
    }
}

- (void)removeConsumptionObserver:(id<SPTDataLoaderConsumptionObserver>)consumptionObserver
{
    if (consumptionObserver) {
        @synchronized(self.consumptionObservers) {
            [self.consumptionObservers removeObjectForKey:consumptionObserver];
        }
    }
}

- (SPTDataLoaderRequestTaskHandler *)handlerForTask:(NSURLSessionTask *)task
{
    NSArray *handlers = nil;
    @synchronized(self.handlers) {
        handlers = [self.handlers copy];
    }
    for (SPTDataLoaderRequestTaskHandler *handler in handlers) {
        if ([handler.task isEqual:task]) {
            return handler;
        }
    }
    return nil;
}

- (void)performRequest:(SPTDataLoaderRequest *)request
requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
{
    if (request.cancellationToken.cancelled) {
        return;
    }
    
    NSString *host = [self.resolver addressForHost:request.URL.host];
    if (![host isEqualToString:request.URL.host] && host) {
        [request addValue:request.URL.host forHeader:SPTDataLoaderRequestHostHeader];
        NSURLComponents *requestComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
        requestComponents.host = host;
        request.URL = requestComponents.URL;
    }
    
    NSURLRequest *urlRequest = request.urlRequest;
    NSURLSessionTask *task = [self.session dataTaskWithRequest:urlRequest];
    SPTDataLoaderRequestTaskHandler *handler = [SPTDataLoaderRequestTaskHandler dataLoaderRequestTaskHandlerWithTask:task
                                                                                                             request:request
                                                                                              requestResponseHandler:requestResponseHandler
                                                                                                         rateLimiter:self.rateLimiter];
    @synchronized(self.handlers) {
        [self.handlers addObject:handler];
    }
    [handler start];
}

- (void)cancelAllLoads
{
    NSArray *handlers = nil;
    @synchronized(self.handlers) {
        handlers = [self.handlers copy];
    }
    for (SPTDataLoaderRequestTaskHandler *handler in handlers) {
        [handler.task cancel];
    }
}

#pragma mark SPTDataLoaderRequestResponseHandlerDelegate

- (id<SPTCancellationToken>)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                                    performRequest:(SPTDataLoaderRequest *)request
{
    id<SPTCancellationToken> cancellationToken = [self.cancellationTokenFactory createCancellationTokenWithDelegate:self
                                                                                                       cancelObject:request];
    request.cancellationToken = cancellationToken;
    
    if ([requestResponseHandler respondsToSelector:@selector(shouldAuthoriseRequest:)]) {
        if ([requestResponseHandler shouldAuthoriseRequest:request]) {
            if ([requestResponseHandler respondsToSelector:@selector(authoriseRequest:)]) {
                [requestResponseHandler authoriseRequest:request];
                return cancellationToken;
            }
        }
    }
    
    [self performRequest:request requestResponseHandler:requestResponseHandler];
    return cancellationToken;
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
    if (![cancellationToken.objectToCancel isKindOfClass:[SPTDataLoaderRequest class]]) {
        return;
    }
    SPTDataLoaderRequest *request = (SPTDataLoaderRequest *)cancellationToken.objectToCancel;
    
    NSArray *handlers = nil;
    @synchronized(self.handlers) {
        handlers = [self.handlers copy];
    }
    for (SPTDataLoaderRequestTaskHandler *handler in handlers) {
        if ([handler.request isEqual:request]) {
            [handler.task cancel];
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
    SPTDataLoaderRequestTaskHandler *handler = [self handlerForTask:dataTask];
    if (completionHandler) {
        completionHandler([handler receiveResponse:response]);
    }
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
    SPTDataLoaderRequestTaskHandler *handler = [self handlerForTask:dataTask];
    [handler receiveData:data];
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error
{
    SPTDataLoaderRequestTaskHandler *handler = [self handlerForTask:task];
    [handler completeWithError:error];
    @synchronized(self.handlers) {
        [self.handlers removeObject:handler];
    }
    
    SPTDataLoaderRequest *request = handler.request;
    
    @synchronized(self.consumptionObservers) {
        for (id<SPTDataLoaderConsumptionObserver> consumptionObserver in self.consumptionObservers) {
            dispatch_block_t observerBlock = ^ {
                int bytesReceived = (int)task.countOfBytesReceived;
                int bytesSent = (int)task.countOfBytesSent;
                
                [consumptionObserver endedRequest:request
                                  bytesDownloaded:bytesReceived
                                    bytesUploaded:bytesSent];
            };
            
            dispatch_queue_t queue = [self.consumptionObservers objectForKey:consumptionObserver];
            if ([NSThread isMainThread] && queue == dispatch_get_main_queue()) {
                observerBlock();
            } else {
                dispatch_async(queue, observerBlock);
            }
        }
    }
}

#pragma mark NSObject

- (void)dealloc
{
    [self cancelAllLoads];
}

@end
