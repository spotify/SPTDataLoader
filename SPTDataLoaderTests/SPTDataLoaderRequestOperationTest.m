#import <XCTest/XCTest.h>

#import "SPTDataLoaderRequestOperation.h"

@interface SPTDataLoaderRequestOperationTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRequestOperation *operation;

@end

@implementation SPTDataLoaderRequestOperationTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.operation = [SPTDataLoaderRequestOperation dataLoaderRequestOperationWithRequest:nil
                                                                                     task:nil
                                                                   requestResponseHandler:nil
                                                                              rateLimiter:nil];
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

@end
