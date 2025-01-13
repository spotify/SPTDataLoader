/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderServerTrustPolicy.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderServerTrustPolicy (Private)

/**
 An NSDictionary where the key is the host and the value is an NSArray of
 NSData representations of certificate files loaded upon instantiation that
 will be used while validating a challenge.
 */
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSData *> *> *trustedHostsAndCertificates;

/**
 Looks up and returns pinned certificates as NSData objects for specified host.

 @param host The host domain to look up pinned certificates

 @return An array of certificate data for the host. If the host is not found/pinned, this value will be nil.
 */
- (nullable NSArray<NSData *> *)certificatesForHost:(NSString *)host;

/**
 Internal method used for validating the provided `NSURLAuthenticationChallenge`
 when validating through the public method -validateChallenge:

 @see -validateChallenge:

 @param trust The X.509 certificate trust of the server.
 @param host  The host domain of the trust. If nil, the validation will return NO.

 @return Whether or not the server for host is trusted
 */
- (BOOL)validateWithTrust:(SecTrustRef)trust host:(nullable NSString *)host;

@end

NS_ASSUME_NONNULL_END
