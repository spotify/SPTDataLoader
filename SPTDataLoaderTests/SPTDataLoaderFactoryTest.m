#import <XCTest/XCTest.h>

#import "SPTDataLoaderFactory+Private.h"

@interface SPTDataLoaderFactoryTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderFactory *factory;

@end

@implementation SPTDataLoaderFactoryTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.factory = [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:nil authorisers:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderFactoryTest

- (void)testNotNil
{
    XCTAssertNotNil(self.factory, @"The factory created should not be nil");
}

- (void)testCreateDataLoader
{
    SPTDataLoader *dataLoader = [self.factory createDataLoader];
    XCTAssertNotNil(dataLoader, @"The data loader created by the factory is nil");
}

@end
