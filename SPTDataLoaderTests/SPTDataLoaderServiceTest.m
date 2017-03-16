/*
 * Copyright (c) 2015-2016 Spotify AB.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderService.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>
#import <SPTDataLoader/SPTDataLoaderResolver.h>
#import <SPTDataLoader/SPTDataLoaderResponse.h>
#import <SPTDataLoader/SPTDataLoaderCancellationToken.h>
#import <SPTDataLoader/SPTDataLoaderServerTrustPolicy.h>

#import "SPTDataLoaderRequestTaskHandler.h"
#import "SPTDataLoaderCancellationTokenImplementation.h"

#import "SPTDataLoaderRequestResponseHandler.h"
#import "NSURLSessionMock.h"
#import "SPTDataLoaderAuthoriserMock.h"
#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoaderRequestResponseHandlerMock.h"
#import "SPTDataLoaderConsumptionObserverMock.h"
#import "NSURLSessionDataTaskMock.h"
#import "SPTDataLoaderRequest+Private.h"
#import "NSURLSessionTaskMock.h"
#import "SPTDataLoaderServerTrustPolicyMock.h"
#import "NSURLAuthenticationChallengeMock.h"
#import "SPTDataLoaderCancellationTokenDelegateMock.h"

@interface SPTDataLoaderService () <NSURLSessionDataDelegate, SPTDataLoaderRequestResponseHandlerDelegate, SPTDataLoaderCancellationTokenDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSMutableArray *handlers;
@property (nonatomic, strong) SPTDataLoaderServerTrustPolicy *serverTrustPolicy;

- (void)cancelAllLoads;

@end

@interface SPTDataLoaderServiceTest : XCTestCase

@property (nonatomic ,strong) SPTDataLoaderService *service;
@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, strong) SPTDataLoaderResolver *resolver;
@property (nonatomic, strong) NSURLSessionMock *session;

@end

@implementation SPTDataLoaderServiceTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:10.0];
    self.resolver = [SPTDataLoaderResolver new];
    self.service = [SPTDataLoaderService dataLoaderServiceWithUserAgent:@"Spotify Test 1.0"
                                                            rateLimiter:self.rateLimiter
                                                               resolver:self.resolver
                                               customURLProtocolClasses:nil];
    self.session = [NSURLSessionMock new];
    self.service.session = self.session;
}

#pragma mark SPTDataLoaderServiceTest

- (void)testNotNil
{
    XCTAssertNotNil(self.service, @"The service should not be nil after construction");
}

- (void)testFactoryNotNil
{
    SPTDataLoaderFactory *factory = [self.service createDataLoaderFactoryWithAuthorisers:nil];
    XCTAssertNotNil(factory, @"The factory should not be nil after creation from the service");
}

- (void)testNoOperationForTask
{
    // Test no crash occurs
    [self.service URLSession:self.session
                    dataTask:[NSURLSessionDataTask new]
          didReceiveResponse:[NSURLResponse new]
           completionHandler:^(NSURLSessionResponseDisposition disposition){}];
}

- (void)testOperationForTaskWithValidTask
{
    // Test no crash occurs
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.service requestResponseHandler:nil performRequest:request];
#pragma clang diagnostic pop
    
    NSURLSessionDataTask *dataTask = self.session.lastDataTask;
    [self.service URLSession:self.session
                    dataTask:dataTask
          didReceiveResponse:[NSURLResponse new]
           completionHandler:^(NSURLSessionResponseDisposition disposition){}];
}

- (void)testResolverChangingAddress
{
    [self.resolver setAddresses:@[ @"192.168.0.1" ] forHost:@"spclient.wg.spotify.com"];
    
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thing"]
                                                        sourceIdentifier:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.service requestResponseHandler:nil performRequest:request];
#pragma clang diagnostic pop
    XCTAssertEqualObjects(request.URL.absoluteString, @"https://192.168.0.1/thing");
}

- (void)testAuthenticatingRequest
{
    SPTDataLoaderAuthoriserMock *authoriserMock = [SPTDataLoaderAuthoriserMock new];
    SPTDataLoaderFactory<SPTDataLoaderRequestResponseHandler> *factory = (SPTDataLoaderFactory<SPTDataLoaderRequestResponseHandler> *)[self.service createDataLoaderFactoryWithAuthorisers:@[ authoriserMock ]];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.URL = (NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thing"];
    [self.service requestResponseHandler:factory performRequest:request];
    XCTAssertEqual(authoriserMock.numberOfCallsToAuthoriseRequest, 1u, @"The service did not check the requests authorisation");
}

- (void)testRequestAuthorised
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    // Test no crash occurs on optional delegate method
    [self.service requestResponseHandler:nil authorisedRequest:nil];
#pragma clang diagnostic pop
}

- (void)testRequestAuthorisationFailed
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    NSError *error = [NSError new];
    [self.service requestResponseHandler:requestResponseHandlerMock failedToAuthoriseRequest:request error:error];
    XCTAssertEqual(requestResponseHandlerMock.numberOfFailedResponseCalls, 1u, @"The service did not call a failed response on a failed authorisation attempt");
}

- (void)testSessionDidReceiveResponse
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.service requestResponseHandler:nil performRequest:request];
#pragma clang diagnostic pop
    
    NSURLSessionDataTask *dataTask = self.session.lastDataTask;
    __block BOOL calledCompletionHandler = NO;
    void (^completionHandler)(NSURLSessionResponseDisposition) = ^(NSURLSessionResponseDisposition disposition) {
        calledCompletionHandler = YES;
    };
    [self.service URLSession:self.session dataTask:dataTask didReceiveResponse:[NSURLResponse new] completionHandler:completionHandler];
    XCTAssertTrue(calledCompletionHandler, @"The service did not call the URL sessions completion handler");
}

- (void)testRedirectionCallbackAbortsTooManyRedirects
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://localhost"]
                                                        sourceIdentifier:@"-"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.service requestResponseHandler:nil performRequest:request];
#pragma clang diagnostic pop
    NSURLSessionTask *task = ((SPTDataLoaderRequestTaskHandler *)[self.service.handlers lastObject]).task;

    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                  statusCode:SPTDataLoaderResponseHTTPStatusCodeMovedPermanently
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:@{ }];

    __block BOOL calledCompletionHandler = NO;
    __block BOOL calledCompletionHandlerWithNil = NO;
    void (^completionHandler)(NSURLRequest *) = ^(NSURLRequest *urlRequest) {
        calledCompletionHandler = YES;

        if (urlRequest == nil) {
            calledCompletionHandlerWithNil = YES;
        } else {
            calledCompletionHandlerWithNil = NO;
        }
    };

    int const redirectsAmountTooMany = 50;

    // Test that redirection is aborted after too many redirects
    for (int i = 0; i <= redirectsAmountTooMany; i++) {
        NSURL *URL = [NSURL URLWithString:@"https://localhost"];
        [self.service URLSession:self.session
                            task:task
      willPerformHTTPRedirection:httpResponse
                      newRequest:[NSURLRequest requestWithURL:URL]
               completionHandler:completionHandler];

        if (calledCompletionHandlerWithNil) {
            break;
        }
    }

    XCTAssertTrue(calledCompletionHandler, @"The service should call the URL redirection completion handler at least once");
    XCTAssertTrue(calledCompletionHandlerWithNil, @"The service should stop redirection after too many redirects");
}

- (void)testRedirectionCallbackDoesNotAbortAfterFewRedirects
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://localhost"]
                                                        sourceIdentifier:@"-"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.service requestResponseHandler:nil performRequest:request];
#pragma clang diagnostic pop
    NSURLSessionTask *task = ((SPTDataLoaderRequestTaskHandler *)[self.service.handlers lastObject]).task;

    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                  statusCode:SPTDataLoaderResponseHTTPStatusCodeMovedPermanently
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:@{ }];

    __block BOOL calledCompletionHandler = NO;
    __block BOOL calledCompletionHandlerWithNil = NO;
    void (^completionHandler)(NSURLRequest *) = ^(NSURLRequest *urlRequest) {
        calledCompletionHandler = YES;

        if (urlRequest == nil) {
            calledCompletionHandlerWithNil = YES;
        } else {
            calledCompletionHandlerWithNil = NO;
        }
    };

    int const redirectsAmountFew = 2;

    // Check that just a few redirects will work fine
    for (int i = 0; i <= redirectsAmountFew; i++) {
        NSURL *URL = [NSURL URLWithString:@"https://localhost"];
        [self.service URLSession:self.session
                            task:task
      willPerformHTTPRedirection:httpResponse
                      newRequest:[NSURLRequest requestWithURL:URL]
               completionHandler:completionHandler];
    }

    XCTAssertTrue(calledCompletionHandler, @"The service should call the URL redirection completion handler at least once");
    XCTAssertFalse(calledCompletionHandlerWithNil, @"The service should not stop redirection after too few redirects");
}

- (void)testSwitchingToDownloadTask
{
    // Test no crash
    [self.service URLSession:self.service.session dataTask:[NSURLSessionDataTask new] didBecomeDownloadTask:[NSURLSessionDownloadTask new]];
}

- (void)testSessionDidReceiveData
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.chunks = YES;
    request.URL = (NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thing"];
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];
    NSData *data = [@"thing" dataUsingEncoding:NSUTF8StringEncoding];
    [self.service URLSession:self.service.session dataTask:self.session.lastDataTask didReceiveData:data];
    XCTAssertEqual(requestResponseHandlerMock.numberOfReceivedDataRequestCalls, 1u, @"The service did not call received data on the request response handler");
}

- (void)testSessionDidComplete
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.URL = (NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thing"];
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];
    [self.service URLSession:self.session task:self.session.lastDataTask didCompleteWithError:nil];
    XCTAssertEqual(requestResponseHandlerMock.numberOfSuccessfulDataResponseCalls, 1u, @"The service did not call successfully received response on the request response handler");
}

- (void)testSessionWillCacheResponse
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.skipNSURLCache = NO;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.service requestResponseHandler:nil performRequest:request];
#pragma clang diagnostic pop
    NSCachedURLResponse *dummyResponse = [NSCachedURLResponse new];
    
    __block NSCachedURLResponse *blockResponse = nil;
    void (^completion)(NSCachedURLResponse *) = ^(NSCachedURLResponse *resp) {
        blockResponse = resp;
    };
    [self.service URLSession:self.session dataTask:self.session.lastDataTask willCacheResponse:dummyResponse completionHandler:completion];
    XCTAssertNotNil(blockResponse, @"The service skipped caching when 'skipNSURLCache' was set to NO");
}

- (void)testSessionWillNotCacheResponse
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.skipNSURLCache = YES;
    request.URL = (NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thing"];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.service requestResponseHandler:nil performRequest:request];
#pragma clang diagnostic pop
    NSCachedURLResponse *dummyResponse = [NSCachedURLResponse new];
    
    __block NSCachedURLResponse *blockResponse = nil;
    void (^completion)(NSCachedURLResponse *) = ^(NSCachedURLResponse *resp) {
        blockResponse = resp;
    };
    [self.service URLSession:self.session dataTask:self.session.lastDataTask willCacheResponse:dummyResponse completionHandler:completion];
    XCTAssertNil(blockResponse, @"The service failed to skip the cache when 'skipNSURLCache' was set to YES");
}

- (void)testConsumptionObserverCalled
{
    SPTDataLoaderConsumptionObserverMock *consumptionObserver = [SPTDataLoaderConsumptionObserverMock new];
    [self.service addConsumptionObserver:consumptionObserver on:dispatch_get_main_queue()];

    NSURL *URL = [NSURL URLWithString:@"https://localhost"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@"-"];
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];
    SPTDataLoaderRequestTaskHandler *handler = self.service.handlers.firstObject;
    NSURLSessionTask *task = [NSURLSessionDataTaskMock new];
    handler.task = task;

    [self.service URLSession:self.session task:task didCompleteWithError:nil];
    XCTAssertEqual(consumptionObserver.numberOfCallsToEndedRequest, 1, @"There should be 1 call to the consumption observer when a request ends");
    [self.service removeConsumptionObserver:consumptionObserver];
    [self.service URLSession:self.session task:[NSURLSessionDataTaskMock new] didCompleteWithError:nil];
    XCTAssertEqual(consumptionObserver.numberOfCallsToEndedRequest, 1, @"There should be 1 call to the consumption observer when the observer has been removed");
}

- (void)testAllowingAllCertificates
{
    self.service.allCertificatesAllowed = YES;
    NSURLSession *session = [NSURLSession new];
    NSURLSessionTask *task = [NSURLSessionTask new];
    NSURLAuthenticationChallenge *challenge = [NSURLAuthenticationChallenge new];
    __block NSInteger nonNilCompletions = 0;
    void(^NSURLSessionCompletionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential *) = ^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential) {
        nonNilCompletions += credential != nil ? 1 : 0;
    };
    [self.service URLSession:session
                        task:task
         didReceiveChallenge:challenge
           completionHandler:NSURLSessionCompletionHandler];
    self.service.allCertificatesAllowed = NO;
    [self.service URLSession:session
                        task:task
         didReceiveChallenge:challenge
           completionHandler:NSURLSessionCompletionHandler];
    XCTAssertEqual(nonNilCompletions, 1, @"There should only be 1 completion once all certificates are not allowed");
}

- (void)testDidReceiveChallengeWithEmptyCompletionHandlerDoesNotCrash
{
    NSURLSession *session = [NSURLSession new];
    NSURLSessionTask *task = [NSURLSessionTask new];
    NSURLAuthenticationChallenge *challenge = [NSURLAuthenticationChallenge new];
    void(^NSURLSessionCompletionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential *) = ^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential) {};
    NSURLSessionCompletionHandler = nil;
    [self.service URLSession:session
                        task:task
         didReceiveChallenge:challenge
           completionHandler:NSURLSessionCompletionHandler];
}

- (void)testCancellingLoads
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    NSURL *URL = [NSURL URLWithString:@"http://www.spotify.com"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@""];
    SPTDataLoaderService *service = [SPTDataLoaderService dataLoaderServiceWithUserAgent:@"Spotify Test 1.0"
                                                                             rateLimiter:self.rateLimiter
                                                                                resolver:self.resolver
                                                                customURLProtocolClasses:nil];
    // Sanity check to make sure we don't receive crashes on dealloc
    [service requestResponseHandler:requestResponseHandlerMock performRequest:request];
    [service cancelAllLoads];
}

- (void)testDidReceiveChallengeWhenNotAllowingAllCertificatesForwardsResponsiblity
{
    NSURLSession *session = [NSURLSession new];
    NSURLSessionTask *task = [NSURLSessionTask new];
    NSURLAuthenticationChallenge *challenge = [NSURLAuthenticationChallenge new];
    __block NSURLSessionAuthChallengeDisposition savedDisposition = NSURLSessionAuthChallengeUseCredential;
    void(^NSURLSessionCompletionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential *) = ^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential) {
        savedDisposition = disposition;
    };
    [self.service URLSession:session
                        task:task
         didReceiveChallenge:challenge
           completionHandler:NSURLSessionCompletionHandler];
    XCTAssertEqual(savedDisposition, NSURLSessionAuthChallengePerformDefaultHandling);
}

- (void)testServerTrustPolicyProvidesProperDispositionAndURLCredentialWhenDidReceiveChallenge
{
    NSURLSession *session = [NSURLSession new];
    NSURLSessionTask *task = [NSURLSessionTask new];
    
    NSURLAuthenticationChallengeMock *challenge = [NSURLAuthenticationChallengeMock mockAuthenticationChallengeWithHost:nil
                                                                                                   authenticationMethod:NSURLAuthenticationMethodServerTrust
                                                                                                            serverTrust:nil];
    SPTDataLoaderServerTrustPolicyMock *serverTrustPolicy = [SPTDataLoaderServerTrustPolicyMock new];
    [self.service setServerTrustPolicy:serverTrustPolicy];
    
    __block NSURLSessionAuthChallengeDisposition savedDisposition = NSURLSessionAuthChallengeUseCredential;
    __block NSURLCredential *savedCredential = nil;
    void(^NSURLSessionCompletionHandler)(NSURLSessionAuthChallengeDisposition, NSURLCredential *) = ^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential) {
        savedDisposition = disposition;
        savedCredential = credential;
    };
    
    // Auth Challenge is considered trusted
    serverTrustPolicy.shouldBeTrusted = YES;
    [self.service URLSession:session
                        task:task
         didReceiveChallenge:challenge
           completionHandler:NSURLSessionCompletionHandler];
    XCTAssertEqual(savedDisposition, NSURLSessionAuthChallengeUseCredential, @"Server Trust Policy should provide auth challenge disposition of .Use when challenge is considered trusted");
    XCTAssertNotNil(savedCredential, @"Server Trust Policy should provide url credential when challenge is considered trusted");
    
    // Auth Challenge is considered untrusted
    serverTrustPolicy.shouldBeTrusted = NO;
    [self.service URLSession:session
                        task:task
         didReceiveChallenge:challenge
           completionHandler:NSURLSessionCompletionHandler];
    
    XCTAssertEqual(savedDisposition, NSURLSessionAuthChallengeCancelAuthenticationChallenge, @"Server Trust Policy should provide auth challenge disposition of .Cancel when challenge is considered untrusted");
    XCTAssertNil(savedCredential, @"Server Trust Policy provided url credential, when challenge is considered trusted, should be nil");
    
    // Server Trust Policy ignored when `allCertificatesAllowed`
    self.service.allCertificatesAllowed = YES;
    serverTrustPolicy.shouldBeTrusted = YES;
    [self.service URLSession:session
                        task:task
         didReceiveChallenge:challenge
           completionHandler:NSURLSessionCompletionHandler];
    XCTAssertEqual(savedDisposition, NSURLSessionAuthChallengeUseCredential, @"Server Trust Policy should be bypassed and auth challenge disposition should be .Use when policy is set and `allCertificatesAllowed` is `YES`");
    XCTAssertNotNil(savedCredential, @"Server Trust Policy should be bypassed and url credential should be non-nil when policy is set and `allCertificatesAllowed` is `YES`");
    
    self.service.allCertificatesAllowed = NO;
    self.service.serverTrustPolicy = nil;
}

- (void)testWillCacheResponseWithNilCompletionHandler
{
    // Sanity check to ensure we don't crash on a nil completion block
    void(^willCacheResponseCompletionBlock)(NSCachedURLResponse *) = nil;
    [self.service URLSession:self.session
                    dataTask:[NSURLSessionDataTask new]
           willCacheResponse:[NSCachedURLResponse new]
           completionHandler:willCacheResponseCompletionBlock];
}

- (void)testConsumptionObserverTakesIntoAccountResponseHeaders
{
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Test consumption observer response headers"];
    SPTDataLoaderConsumptionObserverMock *consumptionObserver = [SPTDataLoaderConsumptionObserverMock new];
    consumptionObserver.endedRequestCallback = ^ {
        [expectation fulfill];
    };
    [self.service addConsumptionObserver:consumptionObserver
                                      on:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];

    NSURL *URL = [NSURL URLWithString:@"https://localhost"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@"-"];
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];
    SPTDataLoaderRequestTaskHandler *handler = self.service.handlers.firstObject;
    NSURLSessionTaskMock *task = [NSURLSessionTaskMock new];
    handler.task = task;

    NSDictionary *headerFields = @{ @"Content-Size" : @"1000" };
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL
                                                              statusCode:400
                                                             HTTPVersion:@"1.1"
                                                            headerFields:headerFields];
    task.mockResponse = response;
    [self.service URLSession:self.session task:task didCompleteWithError:nil];
    [self waitForExpectationsWithTimeout:1.0 handler:nil];
    XCTAssertEqual(consumptionObserver.lastBytesDownloaded, 19, @"The last bytes downloaded is incorrect");
}

- (void)testRedirectionToDifferentHostWithHeaders
{
    NSURL *URL = [NSURL URLWithString:@"https://localhost"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL
                                                        sourceIdentifier:@"-"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.service requestResponseHandler:nil performRequest:request];
#pragma clang diagnostic pop
    NSURLSessionTask *task = ((SPTDataLoaderRequestTaskHandler *)[self.service.handlers lastObject]).task;

    [self.resolver setAddresses:@[ @"newhost" ] forHost:@"localhost"];

    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                                  statusCode:SPTDataLoaderResponseHTTPStatusCodeMovedPermanently
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:@{ }];

    __block BOOL calledCompletionHandler = NO;
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:URL];
    urlRequest.allHTTPHeaderFields = @{ @"Test-Header" : @"Test-Value" };
    [self.service URLSession:self.session
                        task:task
  willPerformHTTPRedirection:httpResponse
                  newRequest:urlRequest
           completionHandler:^(NSURLRequest *newURLRequest) {
               calledCompletionHandler = YES;
               XCTAssertEqualObjects(newURLRequest.URL.host, [self.resolver addressForHost:(NSString * _Nonnull)URL.host]);
               XCTAssertEqualObjects(urlRequest.allHTTPHeaderFields, newURLRequest.allHTTPHeaderFields);
           }];

    XCTAssertTrue(calledCompletionHandler, @"The service should call the URL redirection completion handler at least once");
}

- (void)testDoNotPerformRequestThatIsAlreadyCancelled
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    NSURL *URL = [NSURL URLWithString:@"https://localhost"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@""];
    id<SPTDataLoaderCancellationTokenDelegate> delegate = [SPTDataLoaderCancellationTokenDelegateMock new];
    SPTDataLoaderCancellationTokenImplementation *cancellationToken = [SPTDataLoaderCancellationTokenImplementation cancellationTokenImplementationWithDelegate:delegate
                                                                                                                                                   cancelObject:nil];
    [cancellationToken cancel];
    request.cancellationToken = cancellationToken;
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];
    XCTAssertEqual(self.service.handlers.count, 0u);
}

- (void)testDoNotPerformRequestThatHasNoURL
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];
    XCTAssertEqual(self.service.handlers.count, 0u);
}

- (void)testCancellingRequestFromHandler
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    NSURL *URL = [NSURL URLWithString:@"https://localhost"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@""];
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];
    SPTDataLoaderRequestTaskHandler *handler = self.service.handlers.firstObject;
    NSURLSessionDataTaskMock *task = [NSURLSessionDataTaskMock new];
    handler.task = task;
    [self.service requestResponseHandler:requestResponseHandlerMock cancelRequest:request];
    XCTAssertEqual(task.numberOfCallsToCancel, 1u);
}

- (void)testNotRemovingHandlerIfRetrying
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    NSURL *URL = [NSURL URLWithString:@"https://localhost"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@""];
    request.maximumRetryCount = 10;
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];

    SPTDataLoaderRequestTaskHandler *handler = self.service.handlers.firstObject;
    NSURLSessionTaskMock *task = [NSURLSessionTaskMock new];
    handler.task = task;

    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorDNSLookupFailed userInfo:nil];
    [self.service URLSession:self.session task:task didCompleteWithError:error];

    XCTAssertEqual(self.service.handlers.count, 1u);
}

- (void)testRecreateTaskOnDidComplete
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    NSURL *URL = [NSURL URLWithString:@"https://localhost"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@""];
    request.maximumRetryCount = 10;
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];

    SPTDataLoaderRequestTaskHandler *handler = self.service.handlers.firstObject;
    NSURLSessionTaskMock *task = [NSURLSessionTaskMock new];
    handler.task = task;

    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorDNSLookupFailed userInfo:nil];
    [self.service URLSession:self.session task:task didCompleteWithError:error];

    XCTAssertNotEqualObjects(task, handler.task);
    XCTAssertNotNil(handler.task);
}

- (void)testDoNotRecreateTaskWhenNoHandlerAssociatedWithTask
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    NSURL *URL = [NSURL URLWithString:@"https://localhost"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@""];
    request.maximumRetryCount = 10;
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];

    SPTDataLoaderRequestTaskHandler *handler = self.service.handlers.firstObject;
    NSURLSessionTaskMock *task = [NSURLSessionTaskMock new];
    handler.task = task;

    NSURLSessionTaskMock *otherTask = [NSURLSessionTaskMock new];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorDNSLookupFailed userInfo:nil];
    [self.service URLSession:self.session task:otherTask didCompleteWithError:error];

    XCTAssertEqualObjects(handler.task, task);
}

- (void)testProvidingNewBodyStream
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    NSURL *URL = [NSURL URLWithString:@"https://localhost"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@""];
    [self.service requestResponseHandler:requestResponseHandlerMock performRequest:request];
    [self.service URLSession:self.service.session task:self.session.lastDataTask needNewBodyStream:^(NSInputStream * _Nullable _) {}];
    XCTAssertEqual(requestResponseHandlerMock.numberOfNewBodyStreamCalls, 1u, @"The service did not forward the prompt for a new body stream to the request response handler");
}

@end
