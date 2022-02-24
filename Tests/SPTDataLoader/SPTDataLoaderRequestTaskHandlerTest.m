/*
 Copyright 2015-2022 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <XCTest/XCTest.h>

#import "SPTDataLoaderRequestTaskHandler.h"

#import "SPTDataLoaderRequestResponseHandlerMock.h"
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>
#import <SPTDataLoader/SPTDataLoaderResponse.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import "NSURLSessionTaskMock.h"

@interface SPTDataLoaderRequestTaskHandler ()

@property (nonatomic, assign) NSUInteger retryCount;
@property (nonatomic, strong, readwrite) dispatch_queue_t retryQueue;

- (void)completeIfInFlight;

@end

@interface SPTDataLoaderRequestTaskHandlerTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRequestTaskHandler *handler;

@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler;
@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, strong) SPTDataLoaderRequest *request;
@property (nonatomic, strong) NSURLSessionTaskMock *task;

@end

@implementation SPTDataLoaderRequestTaskHandlerTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    self.rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:10.0];
    self.request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thing"]
                                       sourceIdentifier:nil];
    self.task = [NSURLSessionTaskMock new];
    self.handler = [SPTDataLoaderRequestTaskHandler dataLoaderRequestTaskHandlerWithTask:self.task
                                                                                 request:self.request
                                                                  requestResponseHandler:self.requestResponseHandler
                                                                             rateLimiter:self.rateLimiter];
}

#pragma mark SPTDataLoaderRequestOperationTest

- (void)testNotNil
{
    XCTAssertNotNil(self.handler, @"The handler should not be nil after its construction");
}

- (void)testReceiveDataRelayedToRequestResponseHandler
{
    self.request.chunks = YES;
    NSData *data = [@"thing" dataUsingEncoding:NSUTF8StringEncoding];
    [self.handler receiveData:data];
    XCTAssertEqual(self.requestResponseHandler.numberOfReceivedDataRequestCalls, 1u, @"The handler did not relay the received data onto its request response handler");
}

- (void)testRelaySuccessfulResponse
{
    [self.handler completeWithError:nil];
    XCTAssertEqual(self.requestResponseHandler.numberOfSuccessfulDataResponseCalls, 1u, @"The handler did not relay the successful response onto its request response handler");
}

- (void)testRelayFailedResponse
{
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
    [self.handler receiveResponse:[NSURLResponse new]];
    [self.handler completeWithError:error];
    XCTAssertEqual(self.requestResponseHandler.numberOfFailedResponseCalls, 1u, @"The handler did not relay the failed response onto its request response handler");
}

- (void)testRelayRetryAfterToRateLimiter
{
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:SPTDataLoaderResponseHTTPStatusCodeOK
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:@{ @"Retry-After" : @"60" }];
    [self.handler receiveResponse:httpResponse];
    [self.handler completeWithError:nil];
    XCTAssertEqualWithAccuracy([self.rateLimiter earliestTimeUntilRequestCanBeExecuted:self.request], 59.0, 1.0, @"The retry-after header was not relayed to the rate limiter");
}

- (void)testRelayNewBodyStreamPrompt
{
    [self.handler provideNewBodyStreamWithCompletion:^(NSInputStream * _Nonnull _) {}];
    XCTAssertEqual(self.requestResponseHandler.numberOfNewBodyStreamCalls, 1u);
}

- (void)testRetry
{
    self.handler.retryCount = 10;
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:SPTDataLoaderResponseHTTPStatusCodeNotFound
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:@{ @"Retry-After" : @"60" }];
    [self.handler receiveResponse:httpResponse];
    [self.handler completeWithError:nil];
    XCTAssertEqual(self.requestResponseHandler.numberOfSuccessfulDataResponseCalls, 0u, @"The handler did relay a successful response onto its request response handler when it should have silently retried");
    XCTAssertEqual(self.requestResponseHandler.numberOfFailedResponseCalls, 0u, @"The handler did relay a failed response onto its request response handler when it should have silently retried");
}

- (void)testRetryWithResponseBody
{
    NSData *errorData = [@"error payload" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *successData = [@"success payload" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];

    self.handler.retryQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Request was retried once"];
    __weak __typeof(self) weakSelf = self;
    self.task.resumeCallback = ^ {
        __strong __typeof(self) strongSelf = weakSelf;
        [strongSelf.handler receiveResponse:[NSURLResponse new]];

        if (strongSelf.handler.retryCount == 0) {
            // Let the first request fail
            [strongSelf.handler receiveData:errorData];
            SPTDataLoaderResponse *response = [strongSelf.handler completeWithError:error];

            // When the request gets retried the response should be nil
            XCTAssertNil(response);
        } else {
            // Let the second (retried) request succeed
            [strongSelf.handler receiveData:successData];
            SPTDataLoaderResponse *response = [strongSelf.handler completeWithError:nil];
            XCTAssert([response.body isEqual:successData]);

            [expectation fulfill];
        }
    };

    self.request.maximumRetryCount = 1;
    [self.handler start];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testDataCreationWithContentLengthFromResponse
{
    // It's times like these... I wish I had the SPTSingletonSwizzler ;)
    // Simply don't know how to test NSMutableData dataWithCapacity is called correctly
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:SPTDataLoaderResponseHTTPStatusCodeOK
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:@{ @"Content-Length" : @"60" }];
    NSURLSessionResponseDisposition disposition = [self.handler receiveResponse:httpResponse];
    XCTAssertEqual(disposition, NSURLSessionResponseAllow, @"The operation should have returned an allow disposition");
}

- (void)testStartCallsResume
{
    [self.handler start];
    XCTAssertEqual(self.task.numberOfCallsToResume, 1u, @"The task should be resumed on start if no backoff and rate-limiting is applied");
}

- (void)testResponseCreatedIfNoInitialDataReceived
{
    [self.handler completeWithError:nil];
    XCTAssertNotNil(self.requestResponseHandler.lastReceivedResponse, @"The response should be created even without an initial receivedResponse call");
}

- (void)testDataAppendedWhenNotStreaming
{
    NSString *dataString = @"TEST";
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [self.handler receiveResponse:[NSURLResponse new]];
    [self.handler receiveData:data];
    [self.handler receiveData:data];
    SPTDataLoaderResponse *response = [self.handler completeWithError:nil];
    NSString *receivedString = [[NSString alloc] initWithData:(NSData * _Nonnull)response.body encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects([dataString stringByAppendingString:dataString], receivedString);
}

- (void)testCancelledError
{
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    [self.handler receiveResponse:[NSURLResponse new]];
    [self.handler completeWithError:error];
    XCTAssertEqual(self.requestResponseHandler.numberOfCancelledRequestCalls, 1u, @"The handler did not relay the failed response onto its request response handler");
}

- (void)testRetryWithRateLimiter
{
    self.handler.retryQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    __weak XCTestExpectation *expectation = [self expectationWithDescription:@"Retry limit equals maximum retry count"];
    __weak __typeof(self) weakSelf = self;
    self.task.resumeCallback = ^ {
        __strong __typeof(self) strongSelf = weakSelf;
        NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
        [strongSelf.handler receiveResponse:[NSURLResponse new]];
        [strongSelf.handler completeWithError:error];
        if (strongSelf.request.maximumRetryCount - 1 == strongSelf.task.numberOfCallsToResume) {
            [expectation fulfill];
        }
    };

    self.request.maximumRetryCount = 4;
    [self.handler start];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testCompletingWhenDeallocatingDuringFlight
{
    [self.handler start];
    [self.handler completeIfInFlight];
    XCTAssertEqual(self.requestResponseHandler.numberOfCancelledRequestCalls, 1u);
}

- (void)testCancelledWhenReceivingCancelError
{
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:nil];
    [self.handler receiveResponse:[NSURLResponse new]];
    [self.handler completeWithError:error];
    XCTAssertTrue(self.handler.cancelled);
}

- (void)testUpgradeToDownloadTaskAfterResponse
{
    self.request.backgroundPolicy = SPTDataLoaderRequestBackgroundPolicyOnDemand;
    NSURLSessionResponseDisposition disposition = [self.handler receiveResponse:[NSURLResponse new]];
    XCTAssertEqual(disposition, NSURLSessionResponseBecomeDownload,
                   @"The handler did not return the correct response disposition (.BecomeDownload) given the background policy");
}

- (void)testKeepDataTaskAfterResponse
{
    self.request.backgroundPolicy = SPTDataLoaderRequestBackgroundPolicyDefault;
    NSURLSessionResponseDisposition disposition = [self.handler receiveResponse:[NSURLResponse new]];
    XCTAssertEqual(disposition, NSURLSessionResponseAllow,
                   @"The handler did not return the correct response disposition (.Allow) given the background policy");
}

- (void)testReceiveDataWithNoInitialResponse
{
    NSString *dataString = @"TEST";
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [self.handler receiveData:data];
    [self.handler receiveData:data];
    SPTDataLoaderResponse *response = [self.handler completeWithError:nil];
    NSString *receivedString = [[NSString alloc] initWithData:(NSData * _Nonnull)response.body encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects([dataString stringByAppendingString:dataString], receivedString);
}

@end
