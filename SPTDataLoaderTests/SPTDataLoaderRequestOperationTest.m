#import <XCTest/XCTest.h>

#import "SPTDataLoaderRequestOperation.h"

#import "SPTDataLoaderRequestResponseHandlerMock.h"
#import "SPTDataLoaderRateLimiter.h"
#import "SPTDataLoaderResponse.h"
#import "SPTDataLoaderRequest.h"
#import "NSURLSessionTaskMock.h"

@interface SPTDataLoaderRequestOperationTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRequestOperation *operation;

@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler;
@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, strong) SPTDataLoaderRequest *request;
@property (nonatomic, strong) NSURLSessionTaskMock *task;

@end

@implementation SPTDataLoaderRequestOperationTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    self.rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:10.0];
    self.request = [SPTDataLoaderRequest requestWithURL:[NSURL URLWithString:@"https://spclient.wg.spotify.com/thing"]];
    self.task = [NSURLSessionTaskMock new];
    self.operation = [SPTDataLoaderRequestOperation dataLoaderRequestOperationWithRequest:self.request
                                                                                     task:self.task
                                                                   requestResponseHandler:self.requestResponseHandler
                                                                              rateLimiter:self.rateLimiter];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderRequestOperationTest

- (void)testNotNil
{
    XCTAssertNotNil(self.operation, @"The operation should not be nil after its construction");
}

- (void)testReceiveDataRelayedToRequestResponseHandler
{
    [self.operation receiveData:nil];
    XCTAssertEqual(self.requestResponseHandler.numberOfReceivedDataRequestCalls, 1, @"The operation did not relay the received data onto its request response handler");
}

- (void)testRelaySuccessfulResponse
{
    [self.operation completeWithError:nil];
    XCTAssertEqual(self.requestResponseHandler.numberOfSuccessfulDataResponseCalls, 1, @"The operation did not relay the successful response onto its request response handler");
}

- (void)testRelayFailedResponse
{
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:nil];
    [self.operation receiveResponse:nil];
    [self.operation completeWithError:error];
    XCTAssertEqual(self.requestResponseHandler.numberOfFailedResponseCalls, 1, @"The operation did not relay the failed response onto its request response handler");
}

- (void)testRelayRetryAfterToRateLimiter
{
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:SPTDataLoaderResponseHTTPStatusCodeOK
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:@{ @"Retry-After" : @"60" }];
    [self.operation receiveResponse:httpResponse];
    [self.operation completeWithError:nil];
    XCTAssertEqual(floor([self.rateLimiter earliestTimeUntilRequestCanBeExecuted:self.request]), 59.0, @"The retry-after header was not relayed to the rate limiter");
}

- (void)testRetry
{
    self.request.retryCount = 10;
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:SPTDataLoaderResponseHTTPStatusCodeNotFound
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:@{ @"Retry-After" : @"60" }];
    [self.operation receiveResponse:httpResponse];
    [self.operation completeWithError:nil];
    XCTAssertEqual(self.requestResponseHandler.numberOfSuccessfulDataResponseCalls, 0, @"The operation did relay a successful response onto its request response handler when it should have silently retried");
    XCTAssertEqual(self.requestResponseHandler.numberOfFailedResponseCalls, 0, @"The operation did relay a failed response onto its request response handler when it should have silently retried");
}

- (void)testCancelledRequestReturnsCancelledDisposition
{
    [self.operation cancel];
    NSURLSessionResponseDisposition disposition = [self.operation receiveResponse:nil];
    XCTAssertEqual(disposition, NSURLSessionResponseCancel, @"The cancelled operation should have returned a cancelled disposition");
}

- (void)testDataCreationWithContentLengthFromResponse
{
    // It's times like these... I wish I had the SPTSingletonSwizzler ;)
    // Simply don't know how to test NSMutableData dataWithCapacity is called correctly
    NSHTTPURLResponse *httpResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:SPTDataLoaderResponseHTTPStatusCodeOK
                                                                 HTTPVersion:@"1.1"
                                                                headerFields:@{ @"Content-Length" : @"60" }];
    NSURLSessionResponseDisposition disposition = [self.operation receiveResponse:httpResponse];
    XCTAssertEqual(disposition, NSURLSessionResponseAllow, @"The operation should have returned an allow disposition");
}

- (void)testStartCallsResume
{
    [self.operation start];
    XCTAssertEqual(self.task.numberOfCallsToResume, 1, @"The task should be resumed on start if no backoff and rate-limiting is applied");
}

- (void)testStartWhenCancelled
{
    [self.operation cancel];
    [self.operation start];
    XCTAssertTrue(self.operation.isFinished, @"The operation should be finished if cancelled before start");
    XCTAssertFalse(self.operation.isExecuting, @"The operation should not be executing if cancelled before start");
}

- (void)testRelayCancelToRequestResponseHandler
{
    [self.operation cancel];
    XCTAssertEqual(self.requestResponseHandler.numberOfCancelledRequestCalls, 1, @"The operation did not relay the canceled message to the request response handler");
}

- (void)testCancelCancelsTask
{
    [self.operation cancel];
    XCTAssertEqual(self.task.numberOfCallsToCancel, 1, @"The operation did not call cancel on the task when cancelled");
}

@end
