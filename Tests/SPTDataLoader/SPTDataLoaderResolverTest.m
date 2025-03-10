/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <XCTest/XCTest.h>

#import <SPTDataLoader/SPTDataLoaderResolver.h>

@interface SPTDataLoaderResolverTest : XCTestCase

@property (nonatomic, strong) SPTDataLoaderResolver *resolver;

@end

@implementation SPTDataLoaderResolverTest

#pragma mark XCTestCase

- (void)setUp
{
    [super setUp];
    self.resolver = [SPTDataLoaderResolver new];
}

#pragma mark SPTDataLoaderResolverTest

- (void)testNotNil
{
    XCTAssertNotNil(self.resolver, @"The resolver should not be nil after construction");
}

- (void)testDefaultToHostIfNoOverridingAddress
{
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    NSString *address = [self.resolver addressForHost:(NSString * _Nonnull)URL.host];
    XCTAssertEqualObjects(URL.host, address, @"The address should be identical to the URL host if no overrides are supplied");
}

- (void)testAddressGivenIfReachableForHostOverride
{
    NSString *overrideAddresss = @"192.168.0.1";
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    [self.resolver setAddresses:@[ overrideAddresss ] forHost:(NSString * _Nonnull)URL.host];
    NSString *host = [self.resolver addressForHost:(NSString * _Nonnull)URL.host];
    XCTAssertEqualObjects(host, overrideAddresss, @"The address should be overridden");
}

- (void)testAddressNotGivenIfNotReachableForHostOverride
{
    NSString *overrideAddresss = @"192.168.0.1";
    NSURL *URL = [NSURL URLWithString:@"https://spclient.wg.spotify.com/thingy"];
    [self.resolver setAddresses:@[ overrideAddresss ] forHost:(NSString * _Nonnull)URL.host];
    [self.resolver markAddressAsUnreachable:overrideAddresss];
    NSString *host = [self.resolver addressForHost:(NSString * _Nonnull)URL.host];
    XCTAssertEqualObjects(host, URL.host, @"The address should not be overridden if unreachable");
}

@end
