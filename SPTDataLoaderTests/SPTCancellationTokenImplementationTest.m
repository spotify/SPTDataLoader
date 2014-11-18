#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTCancellationTokenImplementation.h>

#import "SPTCancellationTokenDelegateMock.h"

@interface SPTCancellationTokenImplementationTest : XCTestCase

@property (nonatomic, strong) SPTCancellationTokenImplementation *cancellationToken;

@property (nonatomic, strong) id<SPTCancellationTokenDelegate> delegate;

@end

@implementation SPTCancellationTokenImplementationTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.delegate = [SPTCancellationTokenDelegateMock new];
    self.cancellationToken = [SPTCancellationTokenImplementation cancellationTokenImplementationWithDelegate:self.delegate cancelObject:nil];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTCancellationTokenImplementationTest

- (void)testCancel
{
    [self.cancellationToken cancel];
    SPTCancellationTokenDelegateMock *delegateMock = (SPTCancellationTokenDelegateMock *)self.delegate;
    XCTAssertEqual(delegateMock.numberOfCallsToCancellationTokenDidCancel, 1, @"The delegate cancel method should only have been called once");
    XCTAssertTrue(self.cancellationToken.cancelled, @"The cancellation token did not set itself to cancelled despite being cancelled");
}

- (void)testMultipleCancelsOnlyMakeOneDelegateCall
{
    [self.cancellationToken cancel];
    [self.cancellationToken cancel];
    SPTCancellationTokenDelegateMock *delegateMock = (SPTCancellationTokenDelegateMock *)self.delegate;
    XCTAssertEqual(delegateMock.numberOfCallsToCancellationTokenDidCancel, 1, @"The delegate cancel method should only have been called once");
}

@end
