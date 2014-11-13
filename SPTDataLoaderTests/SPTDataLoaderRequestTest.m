#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderRequest+Private.h"

@interface SPTDataLoaderRequestTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRequest *request;

@property (nonatomic, strong) NSURL *URL;

@end

@implementation SPTDataLoaderRequestTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    self.URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    self.request = [SPTDataLoaderRequest requestWithURL:self.URL];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderRequestTest

- (void)testNotNil
{
    XCTAssertNotNil(self.request, @"The request should not be nil after construction");
}

- (void)testHeadersEmptyInitially
{
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should be empty when initially setting up the request");
}

- (void)testAddValueToNilHeader
{
    [self.request addValue:@"Value" forHeader:nil];
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should not reflect an added value with an empty header");
}

- (void)testAddNilValueToHeader
{
    [self.request addValue:@"Value" forHeader:@"Header"];
    [self.request addValue:nil forHeader:@"Header"];
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should remove a header when added with an empty value");
}

- (void)testAddValueToHeader
{
    [self.request addValue:@"Value" forHeader:@"Header"];
    XCTAssertEqualObjects(self.request.headers, @{ @"Header" : @"Value" }, @"The headers should reflect the added header");
}

- (void)testRemoveHeader
{
    [self.request addValue:@"Value" forHeader:@"Header"];
    [self.request removeHeader:@"Header"];
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should not contain anything after removal");
}

- (void)testURLRequestAddsHostHeader
{
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertEqualObjects(request.allHTTPHeaderFields[@"Host"], self.URL.host, @"The URL request should add a host header field");
}

- (void)testURLRequestContentLengthHeader
{
    NSData *data = [@"Test" dataUsingEncoding:NSUTF8StringEncoding];
    self.request.body = data;
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertEqual(@([request.allHTTPHeaderFields[@"Content-Length"] integerValue]).unsignedIntegerValue, data.length, @"The content-length header was reported incorrectly");
}

- (void)testURLRequestCopyingHeaders
{
    [self.request addValue:@"Value" forHeader:@"Header"];
    NSURLRequest *request = self.request.urlRequest;
    NSDictionary *expectedHeaders = @{ @"Header" : @"Value",
                                       @"Host" : self.URL.host };
    XCTAssertEqualObjects(request.allHTTPHeaderFields, expectedHeaders, @"The headers were not copied appropriately");
}

- (void)testURLRequestCachePolicy
{
    self.request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertEqual(self.request.cachePolicy, request.cachePolicy, @"The URL request does not share the same cache policy as the request");
}

@end
