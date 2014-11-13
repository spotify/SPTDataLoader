#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderRequest.h>

@interface SPTDataLoaderRequestTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRequest *request;

@end

@implementation SPTDataLoaderRequestTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    self.request = [SPTDataLoaderRequest requestWithURL:URL];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderRequestTest

- (void)testNotNil
{
    XCTAssertNotNil(self.request, @"The request should not be nil after construction");
}

- (void)testHeadersEmptyInitially
{
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should be empty when initially setting up the request");
}

@end
