#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderService.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>
#import <SPTDataLoader/SPTDataLoaderResolver.h>
#import <SPTDataLoader/SPTCancellationToken.h>

#import "SPTDataLoaderRequestResponseHandler.h"
#import "NSURLSessionMock.h"
#import "SPTDataLoaderAuthoriserMock.h"
#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoaderRequestResponseHandlerMock.h"

@interface SPTDataLoaderService () <NSURLSessionDataDelegate, SPTDataLoaderRequestResponseHandlerDelegate, SPTCancellationTokenDelegate>

@property (nonatomic, strong) NSURLSession *session;

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
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:10.0];
    self.resolver = [SPTDataLoaderResolver new];
    self.service = [SPTDataLoaderService dataLoaderServiceWithUserAgent:@"Spotify Test 1.0"
                                                            rateLimiter:self.rateLimiter
                                                               resolver:self.resolver];
    self.service.session = [NSURLSessionMock new];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
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
    [self.service URLSession:self.session dataTask:nil didReceiveResponse:nil completionHandler:nil];
}

- (void)testOperationForTaskWithValidTask
{
    // Test no crash occurs
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.service requestResponseHandler:nil performRequest:request];
    
    NSURLSessionDataTask *dataTask = self.session.lastDataTask;
    [self.service URLSession:self.session dataTask:dataTask didReceiveResponse:nil completionHandler:nil];
}

- (void)testResolverChangingAddress
{
    [self.resolver setAddresses:@[ @"192.168.0.1" ] forHost:@"spclient.wg.spotify.com"];
    
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:[NSURL URLWithString:@"https://spclient.wg.spotify.com/thing"]];
    [self.service requestResponseHandler:nil performRequest:request];
    XCTAssertEqualObjects(request.URL.absoluteString, @"https://192.168.0.1/thing");
}

- (void)testAuthenticatingRequest
{
    SPTDataLoaderAuthoriserMock *authoriserMock = [SPTDataLoaderAuthoriserMock new];
    SPTDataLoaderFactory *factory = [self.service createDataLoaderFactoryWithAuthorisers:@[ authoriserMock ]];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.service requestResponseHandler:factory performRequest:request];
    XCTAssertEqual(authoriserMock.numberOfCallsToAuthoriseRequest, 1, @"The service did not check the requests authorisation");
}

- (void)testRequestAuthorised
{
    // Test no crash occurs on optional delegate method
    [self.service requestResponseHandler:nil authorisedRequest:nil];
}

- (void)testRequestAuthorisationFailed
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.service requestResponseHandler:requestResponseHandlerMock failedToAuthoriseRequest:request error:nil];
    XCTAssertEqual(requestResponseHandlerMock.numberOfFailedResponseCalls, 1, @"The service did not call a failed response on a failed authorisation attempt");
}

/**
 * Apparently this is crashing due to an SDK failure: http://osdir.com/ml/general/2014-10/msg10892.html
- (void)testCancellationTokenCancelsOperation
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandlerMock = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    id<SPTCancellationToken> cancellationToken = [self.service requestResponseHandler:requestResponseHandlerMock
                                                                       performRequest:request];
    [cancellationToken cancel];
    XCTAssertEqual(requestResponseHandlerMock.numberOfCancelledRequestCalls, 1, @"The service did not call a cancelled request on a cancellation token cancelling");
}
 */

- (void)testSessionDidReceiveResponse
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.service requestResponseHandler:nil performRequest:request];
    
    NSURLSessionDataTask *dataTask = self.session.lastDataTask;
    __block BOOL calledCompletionHandler = NO;
    void (^completionHandler)(NSURLSessionResponseDisposition) = ^(NSURLSessionResponseDisposition disposition) {
        calledCompletionHandler = YES;
    };
    [self.service URLSession:self.session dataTask:dataTask didReceiveResponse:nil completionHandler:completionHandler];
    XCTAssertTrue(calledCompletionHandler, @"The service did not call the URL sessions completion handler");
}

- (void)testSwitchingToDownloadTask
{
    // Test no crash
    [self.service URLSession:self.service.session dataTask:nil didBecomeDownloadTask:nil];
}

@end
