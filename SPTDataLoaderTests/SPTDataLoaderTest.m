#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoader.h>

#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoader+Private.h"
#import "SPTDataLoaderRequestResponseHandlerDelegateMock.h"
#import "SPTDataLoaderDelegateMock.h"
#import "SPTCancellationTokenDelegateMock.h"
#import "SPTCancellationTokenImplementation.h"
#import "SPTDataLoaderResponse+Private.h"

@interface SPTDataLoaderTest : XCTestCase

@property (nonatomic, strong) SPTDataLoader *dataLoader;

@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerDelegateMock *requestResponseHandlerDelegate;

@property (nonatomic, strong) SPTDataLoaderDelegateMock *delegate;

@end

@implementation SPTDataLoaderTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.requestResponseHandlerDelegate = [SPTDataLoaderRequestResponseHandlerDelegateMock new];
    self.dataLoader = [SPTDataLoader dataLoaderWithRequestResponseHandlerDelegate:self.requestResponseHandlerDelegate];
    self.delegate = [SPTDataLoaderDelegateMock new];
    self.dataLoader.delegate = self.delegate;
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
    XCTAssertNotNil(self.requestResponseHandlerDelegate.lastRequestPerformed, @"Their should be a valid last request performed");
}

- (void)testCancelAllLoads
{
    NSMutableArray *cancellationTokens = [NSMutableArray new];
    NSMutableArray *cancellationTokenDelegates = [NSMutableArray new];
    self.requestResponseHandlerDelegate.tokenCreator =  ^ id<SPTCancellationToken> {
        SPTCancellationTokenDelegateMock *cancellationTokenDelegate = [SPTCancellationTokenDelegateMock new];
        id<SPTCancellationToken> cancellationToken = [SPTCancellationTokenImplementation cancellationTokenImplementationWithDelegate:cancellationTokenDelegate cancelObject:nil];
        [cancellationTokens addObject:cancellationToken];
        [cancellationTokenDelegates addObject:cancellationTokenDelegate];
        return cancellationToken;
    };
    for (NSInteger i = 0; i < 5; ++i) {
        SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
        [self.dataLoader performRequest:request];
    }
    [self.dataLoader cancelAllLoads];
    for (id<SPTCancellationToken> cancellationToken in cancellationTokens) {
        SPTCancellationTokenDelegateMock *delegateMock = cancellationToken.delegate;
        XCTAssertEqual(delegateMock.numberOfCallsToCancellationTokenDidCancel, 1, @"The cancellation tokens delegate was not called");
    }
}

- (void)testRelaySuccessfulResponseToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader successfulResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToSuccessfulResponse, 1, @"The data loader did not relay a successful response to the delegate");
}

- (void)testRelayFailureResponseToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader failedResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToErrorResponse, 1, @"The data loader did not relay a error response to the delegate");
}

- (void)testRelayCancelledRequestToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.dataLoader cancelledRequest:request];
    XCTAssertEqual(self.delegate.numberOfCallsToCancelledRequest, 1, @"The data loader did not relay a cancelled request to the delegate");
}

- (void)testRelayReceivedDataChunkToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.chunks = YES;
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader receivedDataChunk:nil forResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToReceiveDataChunk, 1, @"The data loader did not relay a received data chunk response to the delegate");
}

- (void)testRelayReceivedInitialResponseToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    request.chunks = YES;
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.dataLoader receivedInitialResponse:response];
    XCTAssertEqual(self.delegate.numberOfCallsToReceivedInitialResponse, 1, @"The data loader did not relay a received initial response to the delegate");
}

@end
