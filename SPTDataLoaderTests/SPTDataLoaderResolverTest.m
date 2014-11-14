#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderResolver.h>

@interface SPTDataLoaderResolverTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderResolver *resolver;

@end

@implementation SPTDataLoaderResolverTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.resolver = [SPTDataLoaderResolver new];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderResolverTest

- (void)testNotNil
{
    XCTAssertNotNil(self.resolver, @"The resolver should not be nil after construction");
}

- (void)testDefaultToHostIfNoOverridingAddress
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    NSString *address = [self.resolver addressForHost:URL.host];
    XCTAssertEqualObjects(URL.host, address, @"The address should be identical to the URL host if no overrides are supplied");
}

@end
