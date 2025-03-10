/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLAuthenticationChallengeMock : NSURLAuthenticationChallenge

+ (instancetype)mockAuthenticationChallengeWithHost:(nullable NSString *)host
                               authenticationMethod:(NSString *)authenticationMethod
                                        serverTrust:(nullable SecTrustRef)serverTrust;

@end

NS_ASSUME_NONNULL_END
