#import <XCTest/XCTest.h>

#import "SPTDataLoaderResolverAddress.h"

@interface SPTDataLoaderResolverAddressTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderResolverAddress *address;

@end

@implementation SPTDataLoaderResolverAddressTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.address = [SPTDataLoaderResolverAddress dataLoaderResolverAddressWithAddress:@"192.168.0.1"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderResolverAddressTest

- (void)testNotNil
{
    XCTAssertNotNil(self.address, @"The address should not be nil after construction");
}

- (void)testReachable
{
    XCTAssertTrue(self.address.reachable, @"The address should be reachable");
}

- (void)testNotReachableIfFailed
{
    [self.address failedToReach];
    XCTAssertFalse(self.address.reachable, @"The address should not be reachable");
}

@end
