#import <XCTest/XCTest.h>

#import "SPTDataLoaderRateLimiter.h"

#import <SPTDataLoader/SPTDataLoaderRequest.h>

@interface SPTDataLoaderRateLimiterTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, assign) double requestsPerSecond;

@end

@implementation SPTDataLoaderRateLimiterTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.requestsPerSecond = 10.0;
    self.rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:self.requestsPerSecond];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderRateLimiterTest

- (void)testNotNil
{
    XCTAssertNotNil(self.rateLimiter, @"The rate limiter should not be nil after construction");
}

- (void)testEarliestTimeUntilRequestCanBeRealisedWithRetryAfter
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL];
    NSTimeInterval seconds = 60.0;
    CFAbsoluteTime retryAfter = CFAbsoluteTimeGetCurrent() + seconds;
    [self.rateLimiter setRetryAfter:retryAfter forURL:URL];
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    XCTAssertEqual(floor(earliestTime), floor(seconds - 1.0), @"The retry-after limitation was not respected by the rate limiter");
}

- (void)testEarliestTimeUntilRequestCanBeRealised
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL];
    [self.rateLimiter executedRequest:request];
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    NSString *earliestTimeWithDecimalPrecision = [NSString stringWithFormat:@"%0.1f", earliestTime];
    XCTAssertEqualObjects(earliestTimeWithDecimalPrecision, @"0.1", @"The requests per second limitation was not respected by the rate limiter");
}

- (void)testExecutedRequestWithNilRequest
{
    // Test no crash
    [self.rateLimiter executedRequest:nil];
}

- (void)testRequestsPerSecondDefault
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    double requestsPerSecond = [self.rateLimiter requestsPerSecondForURL:URL];
    XCTAssertEqual(requestsPerSecond, self.requestsPerSecond, @"The requests per second for a URL is not falling back to the default specified in the class constructor");
}

- (void)testRequestsPerSecondCustom
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    double requestsPerSecond = 20.0;
    [self.rateLimiter setRequestsPerSecond:requestsPerSecond forURL:URL];
    double reportedRequestsPerSecond = [self.rateLimiter requestsPerSecondForURL:URL];
    XCTAssertEqual(requestsPerSecond, reportedRequestsPerSecond, @"The requests per second for this URL was not what was explicitly set");
}

- (void)testSetRetryAfterWithNilURL
{
    // Test no crash
    [self.rateLimiter setRetryAfter:60.0 forURL:nil];
}

@end
