/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An object used to enforce certificate trust when presented with an
 `NSURLAuthenticationChallenge` where the authentication method requires
 `SecTrustRef` validation.
 */
@interface SPTDataLoaderServerTrustPolicy : NSObject

/**
 Creates an server trust policy

 @param hostsAndCertificatePaths An NSDictionary where the key is the host and
                                 the value is an NSArray of paths to
                                 certificate files that will be used while
                                 validating a challenge.
 @discussion The NSString key for host can include wildcards
 */
+ (instancetype)policyWithHostsAndCertificatePaths:(NSDictionary<NSString *, NSArray<NSString *> *> *)hostsAndCertificatePaths;

/**
 Evaluates an `NSURLAuthenticationChallenge` against known pinned certificates
 and public keys.

 @return Whether the challenge server is considered trusted or not.
 */
- (BOOL)validateChallenge:(NSURLAuthenticationChallenge *)challenge;

@end

NS_ASSUME_NONNULL_END
