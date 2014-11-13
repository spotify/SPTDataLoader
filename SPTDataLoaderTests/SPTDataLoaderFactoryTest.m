#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderFactory.h>

#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderFactory+Private.h"
#import "SPTDataLoaderRequestResponseHandlerMock.h"
#import "SPTDataLoaderResponse+Private.h"
#import "SPTDataLoaderAuthoriserMock.h"
#import "SPTDataLoaderRequestResponseHandlerDelegateMock.h"

@interface SPTDataLoaderFactory () <SPTDataLoaderRequestResponseHandlerDelegate, SPTDataLoaderAuthoriserDelegate>
@end

@interface SPTDataLoaderFactoryTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderFactory *factory;

@property (nonatomic, strong) SPTDataLoaderRequestResponseHandlerDelegateMock *delegate;

@end

@implementation SPTDataLoaderFactoryTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.delegate = [SPTDataLoaderRequestResponseHandlerDelegateMock new];
    self.factory = [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:self.delegate
                                                                                 authorisers:nil];
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

- (void)testFailedResponse
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.factory failedResponse:response];
    XCTAssertEqual(requestResponseHandler.numberOfFailedResponseCalls, 1, @"The factory did not relay a failed response to the correct handler");
}

- (void)testCancelledRequest
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    [self.factory cancelledRequest:request];
    XCTAssertEqual(requestResponseHandler.numberOfCancelledRequestCalls, 1, @"The factory did not relay a cancelled request to the correct handler");
}

- (void)testReceivedDataChunk
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.factory receivedDataChunk:nil forResponse:response];
    XCTAssertEqual(requestResponseHandler.numberOfReceivedDataRequestCalls, 1, @"The factory did not relay a received data chunk response to the correct handler");
}

- (void)testReceivedInitialResponse
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    [self.factory receivedInitialResponse:response];
    XCTAssertEqual(requestResponseHandler.numberOfReceivedInitialResponseCalls, 1, @"The factory did not relay a received data chunk response to the correct handler");
}

- (void)testShouldAuthoriseRequest
{
    SPTDataLoaderAuthoriserMock *authoriser = [SPTDataLoaderAuthoriserMock new];
    SPTDataLoaderFactory *factory = [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:nil authorisers:@[ authoriser ]];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    BOOL shouldAuthorise = [factory shouldAuthoriseRequest:request];
    XCTAssertTrue(shouldAuthorise, @"The factory should mark the request as authorisable");
}

- (void)testShouldNotAuthoriseRequest
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    BOOL shouldAuthorise = [self.factory shouldAuthoriseRequest:request];
    XCTAssertFalse(shouldAuthorise, @"The factory should not mark the request as authorisable");
}

- (void)testAuthoriseRequest
{
    SPTDataLoaderAuthoriserMock *authoriser = [SPTDataLoaderAuthoriserMock new];
    SPTDataLoaderFactory *factory = [SPTDataLoaderFactory dataLoaderFactoryWithRequestResponseHandlerDelegate:nil authorisers:@[ authoriser ]];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [factory authoriseRequest:request];
    XCTAssertEqual(authoriser.numberOfCallsToAuthoriseRequest, 1, @"The factory did not send an authorise request to the authoriser");
}

- (void)testOfflineChangesCachePolicy
{
    SPTDataLoaderRequestResponseHandlerMock *requestResponseHandler = [SPTDataLoaderRequestResponseHandlerMock new];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    self.factory.offline = YES;
    [self.factory requestResponseHandler:requestResponseHandler performRequest:request];
    XCTAssertEqual(request.cachePolicy, NSURLRequestReturnCacheDataDontLoad, @"The factory did not change the request cache policy to no load when being set to offline");
}

- (void)testRelayToDelegateWhenPerformingRequest
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory requestResponseHandler:nil performRequest:request];
    XCTAssertEqual(request, self.delegate.lastRequestPerformed, @"The factory did not relay the perform request to it's delegate");
}

- (void)testRelayAuthorisingSuccessToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory dataLoaderAuthoriser:nil authorisedRequest:request];
    XCTAssertEqual(request, self.delegate.lastRequestAuthorised, @"The factory did not relay the request authorisation success to it's delegate");
}

- (void)testRelayAuthorisationFailureToDelegate
{
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.factory dataLoaderAuthoriser:nil didFailToAuthoriseRequest:request withError:nil];
    XCTAssertEqual(request, self.delegate.lastRequestFailed, @"The factory did not relay the request authorisation failure to it's delegate");
}

@end
