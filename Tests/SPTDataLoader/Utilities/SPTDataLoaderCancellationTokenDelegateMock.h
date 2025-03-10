/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoaderCancellationToken.h>

@interface SPTDataLoaderCancellationTokenDelegateMock : NSObject <SPTDataLoaderCancellationTokenDelegate>

@property (nonatomic, assign) NSUInteger numberOfCallsToCancellationTokenDidCancel;

@end
