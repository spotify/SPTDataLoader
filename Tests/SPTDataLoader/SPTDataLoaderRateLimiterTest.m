/*
 Copyright 2015-2023 Spotify AB

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

#import "SPTDataLoaderRateLimiter+Private.h"
#import "SPTDataLoaderTimeProviderImplementation.h"
#import "SPTDataLoaderTimeProviderMock.h"

#import <SPTDataLoader/SPTDataLoaderRequest.h>

@interface SPTDataLoaderRateLimiterTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderTimeProviderMock *timeProvider;
@property (nonatomic, strong) SPTDataLoaderRateLimiter *rateLimiter;
@property (nonatomic, assign) double requestsPerSecond;

@end

@implementation SPTDataLoaderRateLimiterTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.requestsPerSecond = 10.0;
    self.timeProvider = [SPTDataLoaderTimeProviderMock new];
    self.rateLimiter = [[SPTDataLoaderRateLimiter alloc] initWithDefaultRequestsPerSecond:self.requestsPerSecond
                                                                             timeProvider:self.timeProvider];
}

#pragma mark SPTDataLoaderRateLimiterTest

- (void)testNotNil
{
    XCTAssertNotNil(self.rateLimiter, @"The rate limiter should not be nil after construction");
}

- (void)testRateLimiterWithDefaultRequestsPerSecondUseExpectedTimeLimiter
{
    // Given
    Class expectedTimeProviderClass = [SPTDataLoaderTimeProviderImplementation class];
    
    // When
    SPTDataLoaderRateLimiter *const rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:self.requestsPerSecond];
    
    // Then
    XCTAssert([rateLimiter.timeProvider isKindOfClass:expectedTimeProviderClass], @"The default timeProvider used by the class method should be a SPTDataLoaderTimeProviderImplementation");
}

- (void)testEarliestTimeUntilRequestCanBeRealisedWithRetryAfter
{
    // Given
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:nil];
    NSTimeInterval seconds = 60.0;
    CFAbsoluteTime retryAfter = self.timeProvider.currentTime + seconds;
    
    // When
    [self.rateLimiter setRetryAfter:retryAfter forURL:URL];
    
    // Then
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    XCTAssertEqualWithAccuracy(earliestTime, seconds, 1.0, @"The retry-after limitation was not respected by the rate limiter");
}

- (void)testEarliestTimeWithCurrentTimeMovingBackwards
{
    // Given
    self.timeProvider.currentTime = 100;
    const double timeDelta = -100;
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:nil];
    [self.rateLimiter executedRequest:request];
    
    // When
    self.timeProvider.currentTime += timeDelta;
    
    // Then
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    XCTAssertEqualWithAccuracy(earliestTime, 0, 0.000000001, @"The earliestTime is not 0 although the currentTime is less than the time of the last request executed");
}

- (void)testEarliestTimeWithCurrentTimeMovingForwardLessThanCutoffTime
{
    // Given
    self.timeProvider.currentTime = 100;
    const CFAbsoluteTime cutoffTime = 0.1; // as we set 10 requests per second
    const CFAbsoluteTime timeDelta = 0.02;
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:nil];
    [self.rateLimiter executedRequest:request];
    
    // When
    self.timeProvider.currentTime += timeDelta;
    
    // Then
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    XCTAssertEqualWithAccuracy(earliestTime, cutoffTime - timeDelta, 0.000000001, @"The earliestTime is not equal to the remaining part of the curoffTime");
}

- (void)testEarliestTimeWithCurrentTimeMovingForwardMoreThanCutoffTime
{
    // Given
    self.timeProvider.currentTime = 100;
    const CFAbsoluteTime timeDelta = 100;
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:nil];
    [self.rateLimiter executedRequest:request];
    
    // When
    self.timeProvider.currentTime -= timeDelta;
    
    // Then
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    XCTAssertEqualWithAccuracy(earliestTime, 0, 0.000000001, @"The earliestTime is not 0 although longer than the cutoff time has passed");
}

- (void)testEarliestTimeUntilRequestCanBeRealised
{
    // Given
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:nil];
    
    // When
    [self.rateLimiter executedRequest:request];
    
    // Then
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    NSString *earliestTimeWithDecimalPrecision = [NSString stringWithFormat:@"%0.1f", earliestTime];
    XCTAssertEqualObjects(earliestTimeWithDecimalPrecision, @"0.1", @"The requests per second limitation was not respected by the rate limiter");
}

- (void)testExecutedRequestWithNilRequest
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    // Test no crash
    [self.rateLimiter executedRequest:nil];
#pragma clang diagnostic pop
}

- (void)testRequestsPerSecondDefault
{
    // Given
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    
    // When
    double requestsPerSecond = [self.rateLimiter requestsPerSecondForURL:URL];
    
    // Then
    XCTAssertEqualWithAccuracy(requestsPerSecond, self.requestsPerSecond, 1.0, @"The requests per second for a URL is not falling back to the default specified in the class constructor");
}

- (void)testRequestsPerSecondCustom
{
    // Given
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    double requestsPerSecond = 20.0;
    
    // When
    [self.rateLimiter setRequestsPerSecond:requestsPerSecond forURL:URL];
    
    // Then
    double reportedRequestsPerSecond = [self.rateLimiter requestsPerSecondForURL:URL];
    XCTAssertEqualWithAccuracy(requestsPerSecond, reportedRequestsPerSecond, 1.0, @"The requests per second for this URL was not what was explicitly set");
}

- (void)testSetRetryAfterWithNilURL
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    // Test no crash
    [self.rateLimiter setRetryAfter:60.0 forURL:nil];
#pragma clang diagnostic pop
}

- (void)testResetRetryAfterAfterSuccessfulExecution
{
    // Given
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:nil];
    NSTimeInterval seconds = 60.0;
    CFAbsoluteTime retryAfter = self.timeProvider.currentTime + seconds;
    
    // When
    [self.rateLimiter setRetryAfter:retryAfter forURL:URL];
    [self.rateLimiter executedRequest:request];
    
    // Then
    NSTimeInterval earliestTime = [self.rateLimiter earliestTimeUntilRequestCanBeExecuted:request];
    XCTAssertEqualWithAccuracy(earliestTime, 0.0, 1.0, @"The earliest time until request can be executed was not reset despite an overwrite of the retry-after rule");
}

@end
