#import <XCTest/XCTest.h>

#import "SPTDataLoaderRequestOperation.h"

#import "SPTDataLoaderRequestResponseHandlerMock.h"
#import "SPTDataLoaderRateLimiter.h"
#import "SPTDataLoaderResponse.h"
#import "SPTDataLoaderRequest.h"

@interface SPTDataLoaderRequestOperationTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRequestOperation *operation;

@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler;
@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, strong) SPTDataLoaderRequest *request;

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
    self.operation = [SPTDataLoaderRequestOperation dataLoaderRequestOperationWithRequest:self.request
                                                                                     task:nil
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

@end
