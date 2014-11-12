#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderService.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderRequestResponseHandler.h"
#import "NSURLSessionMock.h"

@interface SPTDataLoaderService () <NSURLSessionDataDelegate, SPTDataLoaderRequestResponseHandlerDelegate>

@property (nonatomic, strong) NSURLSession *session;

@end

@interface SPTDataLoaderServiceTest : XCTestCase

@property (nonatomic ,strong) SPTDataLoaderService *service;
@property (nonatomic, strong) NSURLSessionMock *session;

@end

@implementation SPTDataLoaderServiceTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.service = [SPTDataLoaderService dataLoaderServiceWithUserAgent:@"Spotify Test 1.0"];
    self.service.session = [NSURLSessionMock new];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderServiceTest

- (void)testNotNil
{
    XCTAssertNotNil(self.service, @"The service should not be nil after construction");
}

- (void)testFactoryNotNil
{
    SPTDataLoaderFactory *factory = [self.service createDataLoaderFactoryWithAuthorisers:nil];
    XCTAssertNotNil(factory, @"The factory should not be nil after creation from the service");
}

- (void)testNoOperationForTask
{
    // Test no crash occurs
    [self.service URLSession:self.session dataTask:nil didReceiveResponse:nil completionHandler:nil];
}

- (void)testOperationForTaskWithValidTask
{
    // Test no crash occurs
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest new];
    [self.service requestResponseHandler:nil performRequest:request];
    
    NSURLSessionDataTask *dataTask = self.session.lastDataTask;
    [self.service URLSession:self.session dataTask:dataTask didReceiveResponse:nil completionHandler:nil];
}

@end
