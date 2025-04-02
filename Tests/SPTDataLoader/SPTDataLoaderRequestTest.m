/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#import "SPTDataLoaderRequest+Private.h"
#import "NSLocaleMock.h"

@interface SPTDataLoaderRequest ()

+ (NSString *)generateLanguageHeaderValue;

@end

@interface SPTDataLoaderRequestTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderRequest *request;

@property (nonatomic, strong) NSURL *URL;

@end

@implementation SPTDataLoaderRequestTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    self.request = [SPTDataLoaderRequest requestWithURL:self.URL sourceIdentifier:nil];
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

- (void)testShouldStopRedirectionNoInitially
{
    XCTAssertFalse(self.request.shouldStopRedirection, @"The shouldStopRedirection should be NO when initially setting up the request");
}

- (void)testAddValueToNilHeader
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.request addValue:@"Value" forHeader:nil];
#pragma clang diagnostic pop
    XCTAssertEqualObjects(self.request.headers, @{}, @"The headers should not reflect an added value with an empty header");
}

- (void)testAddNilValueToHeader
{
    [self.request addValue:@"Value" forHeader:@"Header"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [self.request addValue:nil forHeader:@"Header"];
#pragma clang diagnostic pop
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
                                       @"Accept-Language" : [SPTDataLoaderRequest languageHeaderValue] };
    XCTAssertEqualObjects(request.allHTTPHeaderFields, expectedHeaders, @"The headers were not copied appropriately");
}

- (void)testURLRequestCachePolicy
{
    self.request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertEqual(self.request.cachePolicy, request.cachePolicy, @"The URL request does not share the same cache policy as the request");
}

- (void)testURLRequestMethod
{
    self.request.method = SPTDataLoaderRequestMethodGet;
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertEqualObjects(request.HTTPMethod, @"GET", @"The URL request did not set its HTTP method properly");
}

- (void)testCopy
{
    NSInputStream *inputStream = [NSInputStream inputStreamWithData:[NSData data]];
    self.request.maximumRetryCount = 10;
    self.request.body = [@"Test" dataUsingEncoding:NSUTF8StringEncoding];
    [self.request addValue:@"Value" forHeader:@"Header"];
    self.request.chunks = YES;
    self.request.cachePolicy = NSURLRequestReturnCacheDataDontLoad;
    self.request.skipNSURLCache = YES;
    self.request.method = SPTDataLoaderRequestMethodPost;
    self.request.backgroundPolicy = SPTDataLoaderRequestBackgroundPolicyAlways;
    self.request.bodyStream = inputStream;
    self.request.shouldStopRedirection = YES;
    SPTDataLoaderRequest *request = [self.request copy];
    XCTAssertEqual(request.maximumRetryCount, self.request.maximumRetryCount, @"The retry count was not copied correctly");
    XCTAssertEqualObjects(request.body, self.request.body, @"The body was not copied correctly");
    XCTAssertEqualObjects(request.headers, self.request.headers, @"The headers were not copied correctly");
    XCTAssertEqual(request.chunks, self.request.chunks, @"The chunk was not copied correctly");
    XCTAssertEqual(request.cachePolicy, self.request.cachePolicy, @"The cache policy was not copied correctly");
    XCTAssertEqual(request.skipNSURLCache, self.request.skipNSURLCache, @"'skipNSURLCache' was not copied correctly");
    XCTAssertEqual(request.method, self.request.method, @"The method was not copied correctly");
    XCTAssertEqual(request.backgroundPolicy, self.request.backgroundPolicy, @"The background policy was not copied correctly");
    XCTAssertEqual(request.bodyStream, self.request.bodyStream, @"The body stream was not copied correctly");
    XCTAssertEqual(request.shouldStopRedirection, self.request.shouldStopRedirection, @"The stop redirection was not copied correctly");
}

- (void)testAcceptLanguage
{
    // When the language identifier does not contain a region designator, NSLocale uses the user's preferred region.
    [NSLocaleMock setPreferredLanguages:@[ @"en-US", @"fr-SE", @"ja-SE", @"sv-SE", @"mk-SE", @"nl-SE" ]];

    Method originalMethod = class_getClassMethod(NSLocale.class, @selector(preferredLanguages));
    Method fakeMethod = class_getClassMethod(NSLocaleMock.class, @selector(preferredLanguages));

    IMP originalMethodImplementation = method_getImplementation(originalMethod);
    IMP fakeMethodImplementation = method_getImplementation(fakeMethod);

    method_setImplementation(originalMethod, fakeMethodImplementation);

    NSString *languageValues = [SPTDataLoaderRequest generateLanguageHeaderValue];

    method_setImplementation(originalMethod, originalMethodImplementation);

    XCTAssertEqualObjects(@"en-US;q=1.00, fr-SE;q=0.83, ja-SE;q=0.67, sv-SE;q=0.50, mk-SE;q=0.33, nl-SE;q=0.17", languageValues);
}

- (void)testDescription
{
    XCTAssertNotNil(self.request.description,
                    @"The description shouldn't be nil.");

    NSString *URLString = [NSString stringWithFormat:@"URL = \"%@\"", self.URL.absoluteString];
    XCTAssertTrue([self.request.description containsString:URLString],
                  @"The description should contain the URL of the request.");
}

- (void)testDeleteMethod
{
    self.request.method = SPTDataLoaderRequestMethodDelete;
    XCTAssertEqualObjects(self.request.urlRequest.HTTPMethod, @"DELETE");
}

- (void)testPutMethod
{
    self.request.method = SPTDataLoaderRequestMethodPut;
    XCTAssertEqualObjects(self.request.urlRequest.HTTPMethod, @"PUT");
}

- (void)testPostMethod
{
    self.request.method = SPTDataLoaderRequestMethodPost;
    XCTAssertEqualObjects(self.request.urlRequest.HTTPMethod, @"POST");
}

- (void)testCopyDoesntIncrementUniqueIdentifierBarrier
{
    [self.request copy];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:self.URL sourceIdentifier:nil];
    XCTAssertEqual(request.uniqueIdentifier - 1, self.request.uniqueIdentifier);
}

- (void)testStreamInUrlRequest
{
    NSInputStream *inputStream = [NSInputStream inputStreamWithData:[NSData data]];
    self.request.bodyStream = inputStream;
    NSURLRequest *request = self.request.urlRequest;
    XCTAssertNotNil(request.HTTPBodyStream, @"Should have created an HTTP body stream");
}

- (void)testHeadMethod
{
    self.request.method = SPTDataLoaderRequestMethodHead;
    XCTAssertEqualObjects(self.request.urlRequest.HTTPMethod, @"HEAD");
}

- (void)testPatchMethod
{
    self.request.method = SPTDataLoaderRequestMethodPatch;
    XCTAssertEqualObjects(self.request.urlRequest.HTTPMethod, @"PATCH");
}

@end
