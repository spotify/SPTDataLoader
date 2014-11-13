#import <XCTest/XCTest.h>

#import "SPTDataLoaderRequestOperation.h"

#import "SPTDataLoaderRequestResponseHandlerMock.h"

@interface SPTDataLoaderRequestOperationTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRequestOperation *operation;

@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler;

@end

@implementation SPTDataLoaderRequestOperationTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    self.operation = [SPTDataLoaderRequestOperation dataLoaderRequestOperationWithRequest:nil
                                                                                     task:nil
                                                                   requestResponseHandler:self.requestResponseHandler
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

- (void)testReceiveDataRelayedToRequestResponseHandler
{
    [self.operation receiveData:nil];
    XCTAssertEqual(self.requestResponseHandler.numberOfReceivedDataRequestCalls, 1, @"The operation did not relay the received data onto its request response handler");
}

@end
