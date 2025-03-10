/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An object for tracking a resolver addresses reachability
 */
@interface SPTDataLoaderResolverAddress : NSObject

/**
 The IP address
 */
@property (nonatomic, strong) NSString *address;
/**
 Whether the IP address should currently be considered reachable
 */
@property (nonatomic, assign, readonly, getter = isReachable) BOOL reachable;

/**
 Class constructor
 @param address The IP address to represent
 */
+ (instancetype)dataLoaderResolverAddressWithAddress:(NSString *)address;

/**
 Call when this address has failed to be contacted
 */
- (void)failedToReach;

@end

NS_ASSUME_NONNULL_END
