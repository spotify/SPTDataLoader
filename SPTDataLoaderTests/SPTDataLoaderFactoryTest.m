#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderFactory.h>

#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoaderRequestResponseHandlerMock.h"
#import "SPTDataLoaderResponse+Private.h"

@interface SPTDataLoaderFactory () <SPTDataLoaderRequestResponseHandlerDelegate>
@end

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

- (void)testSuccessfulResponse
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.factory successfulResponse:response];
    XCTAssertEqual(requestResponseHandler.numberOfSuccessfulDataResponseCalls, 1, @"The factory did not relay a successful response to the correct handler");
}

@end
