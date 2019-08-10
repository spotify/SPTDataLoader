/*
 Copyright (c) 2015-2019 Spotify AB.

 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */
#import <SPTDataLoader/SPTDataLoaderService.h>

#import <SPTDataLoader/SPTDataLoaderCancellationToken.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>
#import <SPTDataLoader/SPTDataLoaderResolver.h>
#import <SPTDataLoader/SPTDataLoaderConsumptionObserver.h>
#import <SPTDataLoader/SPTDataLoaderServerTrustPolicy.h>

#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoaderRequest+Private.h"
#import "SPTDataLoaderRequestResponseHandler.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTDataLoaderRequestTaskHandler.h"
#import "NSDictionary+HeaderSize.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderService () <SPTDataLoaderRequestResponseHandlerDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, NSURLSessionDelegate>


@property (nonatomic, strong, nullable) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, strong, nullable) SPTDataLoaderResolver *resolver;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) BOOL isValidSession;
@property (nonatomic, strong) NSOperationQueue *sessionQueue;
@property (nonatomic, strong) NSMutableArray<SPTDataLoaderRequestTaskHandler *> *handlers;
@property (nonatomic, strong) NSMapTable<id<SPTDataLoaderConsumptionObserver>, dispatch_queue_t> *consumptionObservers;
@property (nonatomic, strong) SPTDataLoaderServerTrustPolicy *serverTrustPolicy;
@property (nonatomic, weak, nullable) NSFileManager *fileManager;
@property (nonatomic, weak, nullable) Class dataClass;

@end

@implementation SPTDataLoaderService

#pragma mark SPTDataLoaderService

+ (instancetype)dataLoaderServiceWithUserAgent:(nullable NSString *)userAgent
                                   rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                                      resolver:(nullable SPTDataLoaderResolver *)resolver
                      customURLProtocolClasses:(nullable NSArray<Class> *)customURLProtocolClasses
{
    return [[self alloc] initWithUserAgent:userAgent rateLimiter:rateLimiter resolver:resolver customURLProtocolClasses:customURLProtocolClasses];
}

+ (instancetype)dataLoaderServiceWithConfiguration:(NSURLSessionConfiguration *)configuration
                                   rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                                      resolver:(nullable SPTDataLoaderResolver *)resolver
{
    return [[self alloc] initWithConfiguration:configuration rateLimiter:rateLimiter resolver:resolver];
}

+ (instancetype)dataLoaderServiceWithUserAgent:(nullable NSString *)userAgent
                                   rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                                      resolver:(nullable SPTDataLoaderResolver *)resolver
                      customURLProtocolClasses:(nullable NSArray<Class> *)customURLProtocolClasses
                              qualityOfService:(NSQualityOfService)qualityOfService
{
    return [[self alloc] initWithUserAgent:userAgent
                               rateLimiter:rateLimiter
                                  resolver:resolver
                  customURLProtocolClasses:customURLProtocolClasses
                          qualityOfService:qualityOfService];
}

+ (instancetype)dataLoaderServiceWithConfiguration:(NSURLSessionConfiguration *)configuration
                                       rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                                          resolver:(nullable SPTDataLoaderResolver *)resolver
                                  qualityOfService:(NSQualityOfService)qualityOfService
{
    return [[self alloc] initWithConfiguration:configuration
                                   rateLimiter:rateLimiter
                                      resolver:resolver
                              qualityOfService:qualityOfService];
}

- (instancetype)initWithUserAgent:(nullable NSString *)userAgent
                      rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                         resolver:(nullable SPTDataLoaderResolver *)resolver
         customURLProtocolClasses:(nullable NSArray<Class> *)customURLProtocolClasses
{
    const NSTimeInterval SPTDataLoaderServiceTimeoutInterval = 20.0;
    
    NSString * const SPTDataLoaderServiceUserAgentHeader = @"User-Agent";
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = SPTDataLoaderServiceTimeoutInterval;
    configuration.timeoutIntervalForResource = SPTDataLoaderServiceTimeoutInterval;
    configuration.HTTPShouldUsePipelining = YES;
    configuration.protocolClasses = customURLProtocolClasses;
    if (userAgent) {
        configuration.HTTPAdditionalHeaders = @{ SPTDataLoaderServiceUserAgentHeader : (NSString * _Nonnull)userAgent };
    }
    
    return [self initWithConfiguration:configuration rateLimiter:rateLimiter resolver:resolver];
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration
                          rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                             resolver:(nullable SPTDataLoaderResolver *)resolver
{
    const NSUInteger SPTDataLoaderServiceMaxConcurrentOperations = 32;

    self = [super init];
    if (self) {
        _rateLimiter = rateLimiter;
        _resolver = resolver;

        _sessionQueue = [NSOperationQueue new];
        _sessionQueue.maxConcurrentOperationCount = SPTDataLoaderServiceMaxConcurrentOperations;
        _sessionQueue.name = NSStringFromClass(self.class);
        _isValidSession = YES;
        _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:_sessionQueue];
        _handlers = [NSMutableArray new];
        _consumptionObservers = [NSMapTable weakToStrongObjectsMapTable];

        _fileManager = [NSFileManager defaultManager];
        _dataClass = [NSData class];
    }

    return self;
}

- (instancetype)initWithUserAgent:(nullable NSString *)userAgent
                      rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                         resolver:(nullable SPTDataLoaderResolver *)resolver
         customURLProtocolClasses:(nullable NSArray<Class> *)customURLProtocolClasses
                 qualityOfService:(NSQualityOfService)qualityOfService __OSX_AVAILABLE(10.10)
{
    self = [self initWithUserAgent:userAgent rateLimiter:rateLimiter resolver:resolver customURLProtocolClasses:customURLProtocolClasses];

    if (self) {
        _sessionQueue.qualityOfService = qualityOfService;
    }

    return self;
}

- (instancetype)initWithConfiguration:(NSURLSessionConfiguration *)configuration
                          rateLimiter:(nullable SPTDataLoaderRateLimiter *)rateLimiter
                             resolver:(nullable SPTDataLoaderResolver *)resolver
                     qualityOfService:(NSQualityOfService)qualityOfService __OSX_AVAILABLE(10.10)
{
    self = [self initWithConfiguration:configuration rateLimiter:rateLimiter resolver:resolver];

    if (self) {
        _sessionQueue.qualityOfService = qualityOfService;
    }

    return self;
}

- (SPTDataLoaderFactory *)createDataLoaderFactoryWithAuthorisers:(nullable NSArray<id<SPTDataLoaderAuthoriser>> *)authorisers
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

- (nullable SPTDataLoaderRequestTaskHandler *)handlerForTask:(NSURLSessionTask *)task
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
    
    if (request.URL.host == nil) {
        return;
    }

    if (!self.isValidSession) {
        return;
    }
    
    NSString *host = [self.resolver addressForHost:(NSString * _Nonnull)request.URL.host];
    NSString *requestHost = request.URL.host;
    if (![host isEqualToString:requestHost] && host) {
        NSURLComponents *requestComponents = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
        requestComponents.host = host;
        
        NSURL *URL = requestComponents.URL;
        
        if (URL == nil) {
            return;
        }
        
        request.URL = URL;
    }
    
    NSURLRequest *urlRequest = request.urlRequest;
    NSURLSessionTask *task;
    if (request.backgroundPolicy == SPTDataLoaderRequestBackgroundPolicyAlways) {
        task = [self.session downloadTaskWithRequest:urlRequest];
    } else {
        task = [self.session dataTaskWithRequest:urlRequest];
    }
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

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                performRequest:(SPTDataLoaderRequest *)request
{
    if ([requestResponseHandler respondsToSelector:@selector(shouldAuthoriseRequest:)]) {
        if ([requestResponseHandler shouldAuthoriseRequest:request]) {
            if ([requestResponseHandler respondsToSelector:@selector(authoriseRequest:)]) {
                [requestResponseHandler authoriseRequest:request];
                return;
            }
        }
    }
    
    [self performRequest:request requestResponseHandler:requestResponseHandler];
}

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                 cancelRequest:(SPTDataLoaderRequest *)request
{
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
    SPTDataLoaderRequestTaskHandler *originalHandler = [self handlerForTask:dataTask];
    originalHandler.task = downloadTask;
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    SPTDataLoaderRequestTaskHandler *handler = [self handlerForTask:dataTask];
    [handler receiveData:data];
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
 willCacheResponse:(NSCachedURLResponse *)proposedResponse
 completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    if (!completionHandler) {
        return;
    }
    SPTDataLoaderRequestTaskHandler *handler = [self handlerForTask:dataTask];
    completionHandler(handler.request.skipNSURLCache ? nil : proposedResponse);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
    if (!completionHandler) {
        return;
    }
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    NSURLCredential *credential = nil;
    
    if (self.areAllCertificatesAllowed) {
        SecTrustRef trust = challenge.protectionSpace.serverTrust;
        disposition = NSURLSessionAuthChallengeUseCredential;
        credential = [NSURLCredential credentialForTrust:trust];
    } else if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust] && self.serverTrustPolicy) {
        if ([self.serverTrustPolicy validateChallenge:challenge]) {
            SecTrustRef trust = challenge.protectionSpace.serverTrust;
            disposition = NSURLSessionAuthChallengeUseCredential;
            credential = [NSURLCredential credentialForTrust:trust];
        } else {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    } else {
        // No-op
        // Use default handing
    }
    
    completionHandler(disposition, credential);
}

#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error
{
    SPTDataLoaderRequestTaskHandler *handler = [self handlerForTask:task];
    if (handler == nil) {
        return;
    }
    if (handler.request.backgroundPolicy == SPTDataLoaderRequestBackgroundPolicyAlways) {
        handler.task = [self.session downloadTaskWithRequest:handler.request.urlRequest];
    } else {
        handler.task = [self.session dataTaskWithRequest:handler.request.urlRequest];
    }
    SPTDataLoaderResponse *response = [handler completeWithError:error];
    if (response == nil && !handler.cancelled) {
        return;
    }
    
    @synchronized(self.handlers) {
        [self.handlers removeObject:handler];
    }

    @synchronized(self.consumptionObservers) {
        for (id<SPTDataLoaderConsumptionObserver> consumptionObserver in self.consumptionObservers) {
            dispatch_block_t observerBlock = ^ {
                if (response == nil) {
                    return;
                }
                int bytesSent = (int)task.countOfBytesSent;
                int64_t bytesReceivedExpected = task.countOfBytesExpectedToReceive;
                int bytesReceived;
                if (bytesReceivedExpected == NSURLSessionTransferSizeUnknown) {
                    bytesReceived = (int)task.countOfBytesReceived;
                } else {
                    bytesReceived = (int)bytesReceivedExpected;
                }
                
                bytesSent += task.currentRequest.allHTTPHeaderFields.byteSizeOfHeaders;
                if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)task.response;
                    bytesReceived += httpResponse.allHeaderFields.byteSizeOfHeaders;
                }
                
                [consumptionObserver endedRequestWithResponse:response
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

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    SPTDataLoaderRequestTaskHandler *handler = [self handlerForTask:task];
    if ([handler mayRedirect] == NO) {
        completionHandler(nil);
        return;
    }

    NSURL *newURL = request.URL;
    
    if (newURL.host == nil) {
        completionHandler(nil);
        return;
    }

    // Go through SPTDataLoaderResolver dance and update the URL if needed
    NSString *host = [self.resolver addressForHost:(NSString * _Nonnull)newURL.host];
    NSString *requestHost = newURL.host;
    if (![host isEqualToString:requestHost] && host) {
        NSURLComponents *newRequestComponents = [NSURLComponents componentsWithURL:newURL resolvingAgainstBaseURL:NO];
        newRequestComponents.host = host;
        newURL = newRequestComponents.URL;
    }

    NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:newURL
                                                              cachePolicy:request.cachePolicy
                                                          timeoutInterval:request.timeoutInterval];

    // Sync headers with the original request
    for (NSString *header in request.allHTTPHeaderFields) {
        NSString *value = [request valueForHTTPHeaderField:header];
        [newRequest addValue:value forHTTPHeaderField:header];
    }

    // Proceed with the updated request
    completionHandler(newRequest);
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
 needNewBodyStream:(void (^)(NSInputStream * _Nullable))completionHandler
{
    SPTDataLoaderRequestTaskHandler *handler = [self handlerForTask:task];
    [handler provideNewBodyStreamWithCompletion:completionHandler];
}

#pragma mark NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
    SPTDataLoaderRequestTaskHandler *handler = [self handlerForTask:downloadTask];

    NSFileManager *fileManager = self.fileManager;
    NSString * _Nullable cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    cachePath = [cachePath stringByAppendingPathComponent:@"com.spotify.sptdataloader"];

    if (!cachePath || !location.path || !location.lastPathComponent) {
        [self URLSession:session task:downloadTask didCompleteWithError:nil];
        return;
    }

    [fileManager createDirectoryAtPath:(NSString * _Nonnull)cachePath
           withIntermediateDirectories:true
                            attributes:nil
                                 error:nil];

    NSError *fileError;
    NSString *filePath = [(NSString * _Nonnull)cachePath stringByAppendingPathComponent:(NSString * _Nonnull)location.lastPathComponent];

    // Move tmp file to safe place to read on the session queue
    if ([fileManager moveItemAtPath:(NSString * _Nonnull) location.path toPath:filePath error:&fileError]) {
        [self.sessionQueue addOperationWithBlock:^{
            NSError *readError;
            NSData *data = [self.dataClass dataWithContentsOfFile:filePath options:NSDataReadingUncached error:&readError];

            // Cleanup moved file
            [fileManager removeItemAtPath:filePath error:nil];

            if (!readError) {
                [handler receiveData:data];
            }

            [self URLSession:session task:downloadTask didCompleteWithError:readError];
        }];
    } else {
        [self URLSession:session task:downloadTask didCompleteWithError:fileError];
    }
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error
{
    if ([session isEqual:self.session]) {
        self.isValidSession = NO;
        [self cancelAllLoads];
    }
}

#pragma mark NSObject

- (void)dealloc
{
    [self cancelAllLoads];
}

@end

NS_ASSUME_NONNULL_END
