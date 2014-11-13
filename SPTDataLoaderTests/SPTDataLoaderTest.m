#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoader.h>

#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoader+Private.h"
#import "SPTDataLoaderRequestResponseHandlerDelegateMock.h"

@interface SPTDataLoaderTest : XCTestCase

@property (nonatomic, strong) SPTDataLoader *dataLoader;
@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerDelegateMock *delegate;

@end

@implementation SPTDataLoaderTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.delegate = [SPTDataLoaderRequestResponseHandlerDelegateMock new];
    self.dataLoader = [SPTDataLoader dataLoaderWithRequestResponseHandlerDelegate:self.delegate];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderTest

- (void)testNotNil
{
    XCTAssertNotNil(self.dataLoader, @"The data loader should not be nil after construction");
}

- (void)testPerformRequestRelayedToRequestResponseHandlerDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.dataLoader performRequest:request];
    XCTAssertNotNil(self.delegate.lastRequestPerformed, @"Their should be a valid last request performed");
}

@end
