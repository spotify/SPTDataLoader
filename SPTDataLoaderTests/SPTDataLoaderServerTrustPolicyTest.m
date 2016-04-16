/*
 * Copyright (c) 2015-2016 Spotify AB.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderServerTrustPolicy.h>

#import "SPTDataLoaderServerTrustPolicy+Private.h"

#import <Security/Security.h>

@interface SPTDataLoaderServerTrustPolicyTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderServerTrustPolicy *serverTrustPolicy;

@end

static SecTrustRef SPTDataLoaderUnitTestTrustChainForCertPaths(NSArray<NSString *> *certPaths) {
    NSMutableArray *certs = [NSMutableArray arrayWithCapacity:[certPaths count]];
    for (NSString *path in certPaths) {
        NSData *certData = [NSData dataWithContentsOfFile:path];
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
        id object = (__bridge id)cert;
        [certs addObject:object];
        CFRelease(cert);
    }
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    SecTrustRef trust = NULL;
    SecTrustCreateWithCertificates((__bridge CFTypeRef)certs, policy, &trust);
    CFRelease(policy);
    return trust;
}

static NSArray<NSString *> *SPTDataLoaderServerTrustUnitTestCertificatePathsInDirectory(NSString *inDirectory) {
    NSBundle *bundle = [NSBundle bundleForClass:[SPTDataLoaderServerTrustPolicyTest class]];
    NSArray<NSString *> *paths = [bundle pathsForResourcesOfType:@"der" inDirectory:inDirectory];
    return paths;
}

static NSArray<NSString *> *SPTDataLoaderServerTrustUnitGoogleTestCertificatePaths() {
    return SPTDataLoaderServerTrustUnitTestCertificatePathsInDirectory(@"google");
}

static NSArray<NSString *> *SPTDataLoaderServerTrustUnitSpotifyTestCertificatePaths() {
    return SPTDataLoaderServerTrustUnitTestCertificatePathsInDirectory(@"spotify");
}

static SecTrustRef SPTDataLoaderUnitTestGoogleComServerTrust() {
    NSArray *paths = SPTDataLoaderServerTrustUnitGoogleTestCertificatePaths();
    return SPTDataLoaderUnitTestTrustChainForCertPaths(paths);
}

static SecTrustRef SPTDataLoaderUnitTestSpotifyComServerTrust() {
    NSArray *paths = SPTDataLoaderServerTrustUnitSpotifyTestCertificatePaths();
    return SPTDataLoaderUnitTestTrustChainForCertPaths(paths);
}

@implementation SPTDataLoaderServerTrustPolicyTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSDictionary<NSString *, NSArray<NSString *> *> *dictionary = @{ @"*.spotify.com": SPTDataLoaderServerTrustUnitSpotifyTestCertificatePaths() };
    self.serverTrustPolicy = [SPTDataLoaderServerTrustPolicy policyWithHostsAndCertificatePaths:dictionary];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark SPTDataLoaderServerTrustPolicyTestFunctions

- (void)testGoogleServerTrustCertificatePathsNotNil
{
    NSArray *paths = SPTDataLoaderServerTrustUnitGoogleTestCertificatePaths();
    XCTAssert(paths, @"Unit test certificate paths should not be nil");
    XCTAssertEqual(paths.count, 3, @"Unit test certificate paths should be a count of 3");
}

- (void)testSpotifyServerTrustCertificatePathsNotNil
{
    NSArray *paths = SPTDataLoaderServerTrustUnitSpotifyTestCertificatePaths();
    XCTAssert(paths, @"Unit test certificate paths should not be nil");
    XCTAssertEqual(paths.count, 2, @"Unit test certificate paths should be a count of 3");
}

- (void)testGoogleComServerTrustNotNil
{
    SecTrustRef trust = SPTDataLoaderUnitTestGoogleComServerTrust();
    XCTAssert(trust, @"Unit test trust with provided certificates should not be nil");
}

#pragma mark SPTDataLoaderServerTrustPolicyTest

- (void)testNotNil
{
    XCTAssert(self.serverTrustPolicy, @"The server trust policy should not be nil after construction");
}

- (void)testHostsAndCertificatesNotNil
{
    XCTAssert(self.serverTrustPolicy.trustedHostsAndCertificates, @"The server trust policy's trusted hosts and associated certificates should not be nil after construction");
}

- (void)testHostsAndCertificatesCountShouldBeGreaterThanZero
{
    NSDictionary *trustedHostsAndCertificates = self.serverTrustPolicy.trustedHostsAndCertificates;
    XCTAssertNotEqual(trustedHostsAndCertificates.count, 0, @"The server trust policy's trusted hosts and associated certificates count should not be zero");
}

- (void)testTrustedHostsShouldHaveCertificates
{
    NSDictionary *trustedHostsAndCertificates = self.serverTrustPolicy.trustedHostsAndCertificates;
    NSArray *keys = [trustedHostsAndCertificates allKeys];
    
    for (NSString *key in keys) {
        NSArray *trustedCertificates = trustedHostsAndCertificates[key];
        XCTAssertNotEqual(trustedCertificates.count, 0, @"The server trust policy's trusted hosts should have a minimum of one certificate");
    }
}

#pragma mark Private Internals

- (void)testCertificatesForValidHostShouldNotBeNil
{
    NSString *host = @"www.spotify.com";
    XCTAssert([self.serverTrustPolicy certificatesForHost:host], @"The certificates for host should not be nil when provided a valid host");
}

- (void)testCertificatesForInvalidHostShouldBeNil
{
    NSString *host = @"www.google.com";
    XCTAssertNil([self.serverTrustPolicy certificatesForHost:host], @"The certificates for host should be nil when provided an invalid host");
}

- (void)testCerificatesForHostVariationMatchesWhenKnownHostContainsWildcardShouldNotBeNil
{
    NSString *hostWithWildCard = @"*.google.com";
    NSArray *paths = SPTDataLoaderServerTrustUnitGoogleTestCertificatePaths();
    NSDictionary<NSString *, NSArray<NSString *> *> *dictionary = @{ hostWithWildCard: paths };
    
    SPTDataLoaderServerTrustPolicy *sut = [SPTDataLoaderServerTrustPolicy policyWithHostsAndCertificatePaths:dictionary];
    
    NSArray<NSString *> *hostVariations = @[ @"www.google.com", @"mail.google.com", @"maps.google.com", @"*.google.com" ];
    for (NSString *host in hostVariations) {
        XCTAssert([sut certificatesForHost:host], @"The certificates for this host should not be nil when matcher host string contains wildcard");
    }
}

#pragma mark Negative Validation

- (void)testTrustPolicyConsidersUnknownHostInvalid
{
    SecTrustRef trust = SPTDataLoaderUnitTestGoogleComServerTrust();
    NSString *host = @"www.spotify.com";
    XCTAssertFalse([self.serverTrustPolicy validateWithTrust:trust host:host], @"The server trust policy should consider an unknown host invalid");
}

#pragma mark Positive Validation

- (void)testTrustPolicyValidatesSpotifyComServerTrustWithEntireCertificateChainPinned
{
    SecTrustRef trust = SPTDataLoaderUnitTestSpotifyComServerTrust();
    NSString *host = @"www.spotify.com";
    XCTAssertTrue([self.serverTrustPolicy validateWithTrust:trust host:host], @"The server trust policy should validate a known host and valid trust");
}

@end
