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
    self.request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"]
                                       sourceIdentifier:nil];
    self.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                   statusCode:SPTDataLoaderResponseHTTPStatusCodeOK
                                                  HTTPVersion:@"1.1"
                                                 headerFields:@{ @"Header" : @"Value" }];
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:self.urlResponse];
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
    self.request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"]
                                       sourceIdentifier:nil];
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
    self.request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"]
                                       sourceIdentifier:nil];
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:nil];
    BOOL shouldRetry = [self.response shouldRetry];
    XCTAssertFalse(shouldRetry, @"The response should not retry without having a reason to");
}

- (void)testErrorForHTTPStatusCode
{
    XCTAssertNil(self.response.error, @"The response should not have an implicit error with HTTP status code OK");
}

- (void)testErrorForHTTPStatusCodeNotFound
{
    self.request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"]
                                       sourceIdentifier:nil];
    self.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                   statusCode:SPTDataLoaderResponseHTTPStatusCodeNotFound
                                                  HTTPVersion:@"1.1"
                                                 headerFields:nil];
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:self.urlResponse];
    XCTAssertNotNil(self.response.error, @"An implicit error should have been generated due to the HTTP status code");
    XCTAssertEqualObjects(self.response.error.domain, SPTDataLoaderResponseErrorDomain, @"The implicit error should have the data loader response error domain");
    XCTAssertEqual(self.response.error.code, SPTDataLoaderResponseHTTPStatusCodeNotFound, @"The implicit error should have the same code as the HTTP status code");
}

- (void)testHeaders
{
    XCTAssertEqualObjects(self.response.responseHeaders, @{ @"Header" : @"Value" }, @"The headers were not copied from the response");
}

- (void)testRelativeRetryAfter
{
    self.request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"] sourceIdentifier:nil];
    self.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                   statusCode:SPTDataLoaderResponseHTTPStatusCodeNotFound
                                                  HTTPVersion:@"1.1"
                                                 headerFields:@{ @"Retry-After" : @"60" }];
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:self.urlResponse];
    NSDate *testDate = [NSDate dateWithTimeIntervalSinceNow:60.0];
    XCTAssertEqualWithAccuracy(testDate.timeIntervalSince1970, self.response.retryAfter.timeIntervalSince1970, 1.0, @"The relative retry-after was not as expected");
}

- (void)testAbsoluteRetryAfter
{
    self.request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"]
                                       sourceIdentifier:nil];
    self.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                   statusCode:SPTDataLoaderResponseHTTPStatusCodeNotFound
                                                  HTTPVersion:@"1.1"
                                                 headerFields:@{ @"Retry-After" : @"Fri, 31 Dec 1999 23:59:59 GMT" }];
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:self.urlResponse];
    NSDate *testDate = [NSDate dateWithTimeIntervalSince1970:946684799.0];
    XCTAssertEqualWithAccuracy(testDate.timeIntervalSince1970, self.response.retryAfter.timeIntervalSince1970, 1.0, @"The absolute retry-after was not as expected");
}

- (void)testShouldNotRetryWithInvalidHTTPStatusCode
{
    self.request = [SPTDataLoaderRequest requestWithURL:(NSURL * _Nonnull)[NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"]
                                       sourceIdentifier:nil];
    self.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                   statusCode:SPTDataLoaderResponseHTTPStatusCodeInvalid
                                                  HTTPVersion:@"1.1"
                                                 headerFields:nil];
    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:self.urlResponse];
    BOOL shouldRetry = [self.response shouldRetry];
    XCTAssertFalse(shouldRetry, @"The response should not retry when given the HTTP status code of Invalid");
}

- (void)testShouldNotRetryForCancelled
{
    NSError *connectonError = [NSError errorWithDomain:NSURLErrorDomain
                                                  code:NSURLErrorCancelled
                                              userInfo:nil];
    self.response.error = connectonError;
    BOOL shouldRetry = [self.response shouldRetry];
    XCTAssertFalse(shouldRetry, @"The response should not retry when the connection was cancelled");
}

- (void)testDescription
{
    XCTAssertNotNil(self.response.description,
                    @"The description shouldn't be nil.");
    
    NSString *URLString = [NSString stringWithFormat:@"URL = \"%@\"", self.urlResponse.URL];
    XCTAssertTrue([self.response.description containsString:URLString],
                  @"The description should contain the URL of the response");
    
    NSString *statusCodeString = [NSString stringWithFormat:@"status-code = %ld", (long)self.response.statusCode];
    XCTAssertTrue([self.response.description containsString:statusCodeString],
                  @"The description should contain the status code of the response");
    
    NSString *headersString = [NSString stringWithFormat:@"headers = %@", self.response.responseHeaders];
    XCTAssertTrue([self.response.description containsString:headersString],
                  @"The description should contain the headers code of the response");
}

- (void)testResolvedURLComesFromResponse
{
    NSURL *requestURL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    NSURL *responseURL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/redirected"];

    self.request = [SPTDataLoaderRequest requestWithURL:requestURL
                                       sourceIdentifier:nil];
    self.urlResponse = [[NSHTTPURLResponse alloc] initWithURL:responseURL
                                                   statusCode:SPTDataLoaderResponseHTTPStatusCodeInvalid
                                                  HTTPVersion:@"1.1"
                                                 headerFields:nil];

    self.response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:self.request response:self.urlResponse];

    XCTAssertEqual(self.response.resolvedURL, responseURL);
    XCTAssertNotEqual(self.response.resolvedURL, self.request.URL);
}

@end
