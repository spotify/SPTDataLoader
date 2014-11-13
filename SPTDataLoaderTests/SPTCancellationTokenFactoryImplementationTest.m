#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTCancellationTokenFactoryImplementation.h>

#import "SPTCancellationTokenDelegateMock.h"

@interface SPTCancellationTokenFactoryImplementationTest : XCTestCase

@property (nonatomic, strong) SPTCancellationTokenFactoryImplementation *cancellationTokenFactory;

@end

@implementation SPTCancellationTokenFactoryImplementationTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.cancellationTokenFactory = [SPTCancellationTokenFactoryImplementation new];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTCancellationTokenFactoryImplementationTest

- (void)testCreateCancellationToken
{
    id<SPTCancellationTokenDelegate> delegate = [SPTCancellationTokenDelegateMock new];
    id<SPTCancellationToken> cancellationToken = [self.cancellationTokenFactory createCancellationTokenWithDelegate:delegate];
    XCTAssertNotNil(cancellationToken, @"The factory did not provide a valid cancellation token");
    XCTAssertEqual(delegate, cancellationToken.delegate, @"The factory did not set the delegate on the cancellation token");
}

@end
