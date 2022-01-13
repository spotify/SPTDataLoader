/*
 Copyright 2015-2022 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#import "SPTDataLoaderRequest+Private.h"
#import "NSBundleMock.h"

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
}

- (void)testAcceptLanguageWithNoEnglishLanguages
{
    NSBundleMock *bundleMock = [NSBundleMock new];
    bundleMock.mockPreferredLocalizations = @[ @"fr-CA", @"pt-PT", @"es-419" ];

    Method originalMethod = class_getClassMethod(NSBundle.class, @selector(mainBundle));
    IMP originalMethodImplementation = method_getImplementation(originalMethod);

    IMP fakeMethodImplementation = imp_implementationWithBlock(^ {
        return bundleMock;
    });
    method_setImplementation(originalMethod, fakeMethodImplementation);

    NSString *languageValues = [SPTDataLoaderRequest generateLanguageHeaderValue];

    method_setImplementation(originalMethod, originalMethodImplementation);

    XCTAssertEqualObjects(@"fr-CA, pt-PT;q=0.50, en;q=0.01", languageValues);
}

- (void)testDescription
{
    XCTAssertNotNil(self.request.description,
                    @"The description shouldn't be nil.");
    
    NSString *URLString = [NSString stringWithFormat:@"URL = \"%@\"", self.URL.absoluteString];
    XCTAssertTrue([self.request.description containsString:URLString],
                  @"The description should contain the URL of the request.");
}

- (void)testAcceptLanguageWithMultipleLanguagesContainingEnglish
{
    NSBundleMock *bundleMock = [NSBundleMock new];
    bundleMock.mockPreferredLocalizations = @[ @"fr-CA", @"en", @"pt-PT" ];

    Method originalMethod = class_getClassMethod(NSBundle.class, @selector(mainBundle));
    IMP originalMethodImplementation = method_getImplementation(originalMethod);

    IMP fakeMethodImplementation = imp_implementationWithBlock(^ {
        return bundleMock;
    });
    method_setImplementation(originalMethod, fakeMethodImplementation);

    NSString *languageValues = [SPTDataLoaderRequest generateLanguageHeaderValue];

    method_setImplementation(originalMethod, originalMethodImplementation);

    XCTAssertEqualObjects(@"fr-CA, en;q=0.50", languageValues);
}

- (void)testAcceptLanguageRemovesDuplicateLocalizations
{
    NSBundleMock *bundleMock = [NSBundleMock new];
    bundleMock.mockPreferredLocalizations = @[ @"es-419", @"es-419", @"pt-PT" ];

    Method originalMethod = class_getClassMethod(NSBundle.class, @selector(mainBundle));
    IMP originalMethodImplementation = method_getImplementation(originalMethod);

    IMP fakeMethodImplementation = imp_implementationWithBlock(^ {
        return bundleMock;
    });
    method_setImplementation(originalMethod, fakeMethodImplementation);

    NSString *languageValues = [SPTDataLoaderRequest generateLanguageHeaderValue];

    method_setImplementation(originalMethod, originalMethodImplementation);

    XCTAssertEqualObjects(@"es-419, pt-PT;q=0.50, en;q=0.01", languageValues);
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
