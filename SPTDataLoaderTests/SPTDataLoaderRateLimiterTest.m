#import <XCTest/XCTest.h>

#import "SPTDataLoaderRateLimiter.h"

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

@end
