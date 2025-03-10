/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderServerTrustPolicy.h>
#import <Foundation/Foundation.h>

@interface SPTDataLoaderServerTrustPolicyMock : SPTDataLoaderServerTrustPolicy

@property (nonatomic, assign) BOOL shouldBeTrusted;

@end
