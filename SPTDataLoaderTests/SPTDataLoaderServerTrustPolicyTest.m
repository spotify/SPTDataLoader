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

#import "NSURLAuthenticationChallengeMock.h"

#import <Security/Security.h>

#define SPTDataLoaderUnitTestReleaseIfNonNull(value) ({ \
    if (value != NULL) { \
        CFRelease(value); \
    } \
})

@interface SPTDataLoaderServerTrustPolicyValidationSpy : SPTDataLoaderServerTrustPolicy

@property (nonatomic, assign) BOOL didAttemptValidation;

@end

@interface SPTDataLoaderServerTrustPolicyTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderServerTrustPolicy *serverTrustPolicy;

@end

static SecTrustRef SPTDataLoaderUnitTestCreateTrustChainForCertPaths(NSArray<NSString *> *certPaths) {
    NSMutableArray *certs = [NSMutableArray arrayWithCapacity:[certPaths count]];
    for (NSString *path in certPaths) {
        NSData *certData = [NSData dataWithContentsOfFile:path];
        if (!certData) {
            continue;
        }
        SecCertificateRef cert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certData);
        id object = (__bridge id)cert;
        [certs addObject:object];
        CFRelease(cert);
    }
    if (![certs count]) {
        return NULL;
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

static SecTrustRef SPTDataLoaderUnitTestCreateGoogleComServerTrust() {
    NSArray *paths = SPTDataLoaderServerTrustUnitGoogleTestCertificatePaths();
    return SPTDataLoaderUnitTestCreateTrustChainForCertPaths(paths);
}

static SecTrustRef SPTDataLoaderUnitTestCreateSpotifyComServerTrust() {
    NSArray *paths = SPTDataLoaderServerTrustUnitSpotifyTestCertificatePaths();
    return SPTDataLoaderUnitTestCreateTrustChainForCertPaths(paths);
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
    XCTAssertEqual(paths.count, 3u, @"Unit test certificate paths should be a count of 3");
}

- (void)testSpotifyServerTrustCertificatePathsNotNil
{
    NSArray *paths = SPTDataLoaderServerTrustUnitSpotifyTestCertificatePaths();
    XCTAssert(paths, @"Unit test certificate paths should not be nil");
    XCTAssertEqual(paths.count, 2u, @"Unit test certificate paths should be a count of 3");
}

- (void)testGoogleComServerTrustNotNil
{
    SecTrustRef trust = SPTDataLoaderUnitTestCreateGoogleComServerTrust();
    XCTAssert(trust, @"Unit test trust with provided certificates should not be nil");
    SPTDataLoaderUnitTestReleaseIfNonNull(trust);
}

- (void)testSpotifyComServerTrustNotNil
{
    SecTrustRef trust = SPTDataLoaderUnitTestCreateSpotifyComServerTrust();
    XCTAssert(trust, @"Unit test trust with provided certificates should not be nil");
    SPTDataLoaderUnitTestReleaseIfNonNull(trust);
}

#pragma mark SPTDataLoaderServerTrustPolicyTest

- (void)testNotNil
{
    XCTAssert(self.serverTrustPolicy, @"The server trust policy should not be nil after construction");
}

- (void)testNil
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    SPTDataLoaderServerTrustPolicy *sut = [SPTDataLoaderServerTrustPolicy policyWithHostsAndCertificatePaths:nil];
#pragma clang diagnostic pop
    XCTAssertNil(sut, @"Server trust policy instantiated without hosts + certificates should return nil");
}

- (void)testHostsAndCertificatesNotNil
{
    XCTAssert(self.serverTrustPolicy.trustedHostsAndCertificates, @"The server trust policy's trusted hosts and associated certificates should not be nil after construction");
}

- (void)testHostsAndCertificatesCountShouldBeGreaterThanZero
{
    NSDictionary *trustedHostsAndCertificates = self.serverTrustPolicy.trustedHostsAndCertificates;
    XCTAssertNotEqual(trustedHostsAndCertificates.count, 0u, @"The server trust policy's trusted hosts and associated certificates count should not be zero");
}

- (void)testTrustedHostsShouldHaveCertificates
{
    NSDictionary *trustedHostsAndCertificates = self.serverTrustPolicy.trustedHostsAndCertificates;
    NSArray *keys = [trustedHostsAndCertificates allKeys];
    
    for (NSString *key in keys) {
        NSArray *trustedCertificates = trustedHostsAndCertificates[key];
        XCTAssertNotEqual(trustedCertificates.count, 0u, @"The server trust policy's trusted hosts should have a minimum of one certificate");
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

- (void)testUnknownCertificateForKnownHostShouldBeInvalid
{
    SecTrustRef trust = SPTDataLoaderUnitTestCreateGoogleComServerTrust();
    NSString *host = @"www.spotify.com";
    XCTAssert([self.serverTrustPolicy certificatesForHost:host], @"The server trust policy should consider this host known");
    XCTAssertFalse([self.serverTrustPolicy validateWithTrust:trust host:host], @"The server trust policy should consider an invalid certificate invalid");
    SPTDataLoaderUnitTestReleaseIfNonNull(trust);
}

- (void)testUnknownHostShouldBeInvalid
{
    SecTrustRef trust = SPTDataLoaderUnitTestCreateGoogleComServerTrust();
    NSString *host = @"www.google.com";
    XCTAssertNil([self.serverTrustPolicy certificatesForHost:host], @"The server trust policy should consider this host unknown");
    XCTAssertFalse([self.serverTrustPolicy validateWithTrust:trust host:host], @"The server trust policy should consider an unknown host invalid");
    SPTDataLoaderUnitTestReleaseIfNonNull(trust);
}

#pragma mark Positive Validation

- (void)testValidatesSpotifyComServerTrustWithCertificateChainPinned
{
    SecTrustRef trust = SPTDataLoaderUnitTestCreateSpotifyComServerTrust();
    NSString *host = @"www.spotify.com";
    XCTAssertTrue([self.serverTrustPolicy validateWithTrust:trust host:host], @"The server trust policy should validate a known host and valid trust");
    SPTDataLoaderUnitTestReleaseIfNonNull(trust);
}

#pragma mark Authentication Challenge Interface

- (void)testMalformedAuthenticationChallengeShouldBypassValidation
{
    NSMutableArray<NSURLAuthenticationChallengeMock *> *malformedAuthenticationChallenges = [NSMutableArray arrayWithCapacity:3];
    
    NSString *host = @"www.spotify.com";
    SecTrustRef trust = SPTDataLoaderUnitTestCreateSpotifyComServerTrust();
    NSString *validAuthenticationMethod = NSURLAuthenticationMethodServerTrust;
    NSString *invalidAuthenticationMethod = NSURLAuthenticationMethodHTTPBasic;
    
    // Invalid Host
    {
        NSURLAuthenticationChallengeMock *authenticationChallenge = [NSURLAuthenticationChallengeMock mockAuthenticationChallengeWithHost:nil
                                                                                                                     authenticationMethod:validAuthenticationMethod
                                                                                                                              serverTrust:trust];
        [malformedAuthenticationChallenges addObject:authenticationChallenge];
    }
    
    // Invalid Trust
    {
        NSURLAuthenticationChallengeMock *authenticationChallenge = [NSURLAuthenticationChallengeMock mockAuthenticationChallengeWithHost:host
                                                                                                                     authenticationMethod:validAuthenticationMethod
                                                                                                                              serverTrust:nil];
        [malformedAuthenticationChallenges addObject:authenticationChallenge];
    }
    
    // Invalid Authentication Method
    {
        NSURLAuthenticationChallengeMock *authenticationChallenge = [NSURLAuthenticationChallengeMock mockAuthenticationChallengeWithHost:host
                                                                                                                     authenticationMethod:invalidAuthenticationMethod
                                                                                                                              serverTrust:trust];
        [malformedAuthenticationChallenges addObject:authenticationChallenge];
    }
    
    for (NSURLAuthenticationChallengeMock *authenticationChallenge in malformedAuthenticationChallenges) {
        NSDictionary<NSString *, NSArray<NSString *> *> *dictionary = @{ @"*.spotify.com": SPTDataLoaderServerTrustUnitSpotifyTestCertificatePaths() };
        SPTDataLoaderServerTrustPolicyValidationSpy *sut = [SPTDataLoaderServerTrustPolicyValidationSpy policyWithHostsAndCertificatePaths:dictionary];
        XCTAssertFalse([sut validateChallenge:authenticationChallenge], @"The server trust policy should return NO when attempting to validate an authentication challenge when it is considered incapable of being validated");
        XCTAssertFalse([sut didAttemptValidation], @"The server trust policy should bypass validation of an authentication challenge when it is considered incapable of being validated");
    }
    
    SPTDataLoaderUnitTestReleaseIfNonNull(trust);
}

- (void)testValidAuthenticationChallengeShouldTriggerValidationAttempt
{
    NSString *host = @"www.google.com";
    SecTrustRef trust = SPTDataLoaderUnitTestCreateGoogleComServerTrust();
    NSString *authenticationMethod = NSURLAuthenticationMethodServerTrust;
    
    NSURLAuthenticationChallengeMock *authenticationChallenge = [NSURLAuthenticationChallengeMock mockAuthenticationChallengeWithHost:host
                                                                                                                 authenticationMethod:authenticationMethod
                                                                                                                          serverTrust:trust];
    SPTDataLoaderUnitTestReleaseIfNonNull(trust);
    NSDictionary<NSString *, NSArray<NSString *> *> *dictionary = @{ @"*.spotify.com": SPTDataLoaderServerTrustUnitSpotifyTestCertificatePaths() };
    SPTDataLoaderServerTrustPolicyValidationSpy *sut = [SPTDataLoaderServerTrustPolicyValidationSpy policyWithHostsAndCertificatePaths:dictionary];
    [sut validateChallenge:authenticationChallenge];
    XCTAssertTrue([sut didAttemptValidation], @"The server trust policy should attempt validation of an authentication challenge when challenge contains required parameters");
}

@end

@implementation SPTDataLoaderServerTrustPolicyValidationSpy

- (BOOL)validateWithTrust:(SecTrustRef)trust host:(NSString *)host
{
    [self setDidAttemptValidation:YES];
    
    return [super validateWithTrust:trust host:host];
}

@end
