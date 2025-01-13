/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An object for keeping track of IP addresses to use for hosts
 */
@interface SPTDataLoaderResolver : NSObject

/**
 Find a known valid address for the host
 @param host The host to resolve
 */
- (NSString *)addressForHost:(NSString *)host;
/**
 Set a list of valid addresses for the host
 @param addresses An NSArray of NSString objects denoting an address
 @param host The host tied to these addresses
 */
- (void)setAddresses:(NSArray<NSString *> *)addresses forHost:(NSString *)host;
/**
 Mark an address as unreachable
 @param address The address that has become unreachable
 */
- (void)markAddressAsUnreachable:(NSString *)address;

@end

NS_ASSUME_NONNULL_END
