#import <XCTest/XCTest.h>

#import "SPTDataLoaderRateLimiter.h"

#import <SPTDataLoader/SPTDataLoaderRequest.h>

@interface SPTDataLoaderRateLimiterTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;

@end

@implementation SPTDataLoaderRateLimiterTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:10.0];
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

@end
