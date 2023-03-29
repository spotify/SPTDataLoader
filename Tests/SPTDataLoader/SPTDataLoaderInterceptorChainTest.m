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

#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderInterceptorResult.h>

#import "SPTDataLoaderInterceptorChain.h"
#import "SPTDataLoaderInterceptorMock.h"
#import "SPTDataLoaderResponse+Private.h"

@interface SPTDataLoaderInterceptorChainTest: XCTestCase

@end

@implementation SPTDataLoaderInterceptorChainTest

-(void)testRequestResponseIsUnchangedWithNoInterceptors
{
    SPTDataLoaderInterceptorChain *chain = [[SPTDataLoaderInterceptorChain alloc] initWithInterceptors:@[]];
    NSURL *testURL = [NSURL URLWithString:@"https://somewhere"];
    SPTDataLoaderRequest *request =
        [SPTDataLoaderRequest requestWithURL: testURL
                            sourceIdentifier:@"test"
    ];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];

    SPTDataLoaderInterceptorResult *result = [chain decorateRequest:request];
    XCTAssertTrue(result.type == SPTDataLoaderInterceptResultSuccess);
    XCTAssertEqual(result.value, request);

    result = [chain decorateResponse:response];
    XCTAssertTrue(result.type == SPTDataLoaderInterceptResultSuccess);
    XCTAssertEqual(result.value, response);
}

-(void)testRequestResponseInterceptorGetCalled
{
    SPTDataLoaderInterceptorMock *interceptor1 = [SPTDataLoaderInterceptorMock new];
    SPTDataLoaderInterceptorMock *interceptor2 = [SPTDataLoaderInterceptorMock new];
    SPTDataLoaderInterceptorMock *interceptor3 = [SPTDataLoaderInterceptorMock new];
    NSURL *testURL = [NSURL URLWithString:@"https://somewhere"];
    SPTDataLoaderRequest *request =
        [SPTDataLoaderRequest requestWithURL: testURL
                            sourceIdentifier:@"test"
    ];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];

    SPTDataLoaderInterceptorChain *chain =
        [[SPTDataLoaderInterceptorChain alloc] initWithInterceptors:@[interceptor1, interceptor2, interceptor3]];

    [chain decorateRequest:request];
    [chain decorateResponse:response];
    XCTAssertEqual(interceptor1.numberOfCallsToInterceptorRequest, 1u);
    XCTAssertEqual(interceptor1.numberOfCallsToInterceptorResponse, 1u);
    XCTAssertEqual(interceptor2.numberOfCallsToInterceptorRequest, 1u);
    XCTAssertEqual(interceptor2.numberOfCallsToInterceptorResponse, 1u);
    XCTAssertEqual(interceptor3.numberOfCallsToInterceptorRequest, 1u);
    XCTAssertEqual(interceptor3.numberOfCallsToInterceptorResponse, 1u);
}

-(void)testRequestBailoutInterceptor
{
    SPTDataLoaderInterceptorMock *interceptor1 = [SPTDataLoaderInterceptorMock new];
    SPTDataLoaderInterceptorMock *interceptor2 = [SPTDataLoaderInterceptorMock new];
    NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    interceptor2.interceptorRequestBlock = ^(SPTDataLoaderRequest *request) {
        return [SPTDataLoaderInterceptorResult failure:error];
    };
    SPTDataLoaderInterceptorMock *interceptor3 = [SPTDataLoaderInterceptorMock new];
    NSURL *testURL = [NSURL URLWithString:@"https://somewhere"];
    SPTDataLoaderRequest *request =
        [SPTDataLoaderRequest requestWithURL: testURL
                            sourceIdentifier:@"test"
    ];
    SPTDataLoaderInterceptorChain *chain =
        [[SPTDataLoaderInterceptorChain alloc] initWithInterceptors:@[interceptor1, interceptor2, interceptor3]];

    SPTDataLoaderInterceptorResult *result = [chain decorateRequest:request];
    XCTAssertTrue(result.type == SPTDataLoaderInterceptResultFailure);
    XCTAssertEqual(result.error, error);
    XCTAssertEqual(interceptor1.numberOfCallsToInterceptorRequest, 1u);
    XCTAssertEqual(interceptor2.numberOfCallsToInterceptorRequest, 1u);
    XCTAssertEqual(interceptor3.numberOfCallsToInterceptorRequest, 0u);
}

-(void)testResponseBailoutInterceptor
{
    SPTDataLoaderInterceptorMock *interceptor1 = [SPTDataLoaderInterceptorMock new];
    SPTDataLoaderInterceptorMock *interceptor2 = [SPTDataLoaderInterceptorMock new];
    NSError *error = [NSError errorWithDomain:@"test" code:1 userInfo:nil];
    interceptor2.interceptorResponseBlock = ^(SPTDataLoaderResponse *response) {
        return [SPTDataLoaderInterceptorResult failure:error];
    };
    SPTDataLoaderInterceptorMock *interceptor3 = [SPTDataLoaderInterceptorMock new];
    NSURL *testURL = [NSURL URLWithString:@"https://somewhere"];
    SPTDataLoaderRequest *request =
        [SPTDataLoaderRequest requestWithURL: testURL
                            sourceIdentifier:@"test"
    ];
    SPTDataLoaderResponse *response = [SPTDataLoaderResponse dataLoaderResponseWithRequest:request response:nil];
    SPTDataLoaderInterceptorChain *chain =
        [[SPTDataLoaderInterceptorChain alloc] initWithInterceptors:@[interceptor1, interceptor2, interceptor3]];

    SPTDataLoaderInterceptorResult *result = [chain decorateResponse:response];
    XCTAssertTrue(result.type == SPTDataLoaderInterceptResultFailure);
    XCTAssertEqual(result.error, error);
    XCTAssertEqual(interceptor1.numberOfCallsToInterceptorResponse, 1u);
    XCTAssertEqual(interceptor2.numberOfCallsToInterceptorResponse, 1u);
    XCTAssertEqual(interceptor3.numberOfCallsToInterceptorResponse, 0u);
}

@end
