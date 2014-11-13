#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderResponse.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderResponse+Private.h"

@interface SPTDataLoaderResponseTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderResponse *response;

@property (nonatomic, strong) SPTDataLoaderRequest *request;
@property (nonatomic, strong) NSURLResponse *urlResponse;

@end

@implementation SPTDataLoaderResponseTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.request = [SPTDataLoaderRequest requestWithURL:[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"]];
    self.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                   statusCode:SPTDataLoaderResponseHTTPStatusCodeOK
                                                  HTTPVersion:@"1.1"
                                                 headerFields:nil];
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:self.urlResponse];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderResponseTest

- (void)testNotNil
{
    XCTAssertNotNil(self.response, @"The response should not be nil");
}

- (void)testShouldRetryWithOKHTTPStatusCode
{
    BOOL shouldRetry = [self.response shouldRetry];
    XCTAssertFalse(shouldRetry, @"The response should not retry when given the HTTP status code of OK");
}

- (void)testShouldRetryWithNotFoundHTTPStatusCode
{
    self.request = [SPTDataLoaderRequest requestWithURL:[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"]];
    self.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                   statusCode:SPTDataLoaderResponseHTTPStatusCodeNotFound
                                                  HTTPVersion:@"1.1"
                                                 headerFields:nil];
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:self.urlResponse];
    BOOL shouldRetry = [self.response shouldRetry];
    XCTAssertTrue(shouldRetry, @"The response should retry when given the HTTP status code of Not Found");
}

- (void)testShouldRetryForCertificateRejection
{
    NSError *connectonError = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:NSURLErrorClientCertificateRejected
                                              userInfo:nil];
    self.response.error = connectonError;
    BOOL shouldRetry = [self.response shouldRetry];
    XCTAssertFalse(shouldRetry, @"The response should not retry when the certificate was rejected");
}

- (void)testShouldRetryForTimedOut
{
    NSError *connectonError = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:NSURLErrorTimedOut
                                              userInfo:nil];
    self.response.error = connectonError;
    BOOL shouldRetry = [self.response shouldRetry];
    XCTAssertTrue(shouldRetry, @"The response should retry when the connection timed out");
}

- (void)testShouldRetryDefault
{
    self.request = [SPTDataLoaderRequest requestWithURL:[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"]];
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:nil];
    BOOL shouldRetry = [self.response shouldRetry];
    XCTAssertFalse(shouldRetry, @"The response should not retry without having a reason to");
}

@end
