/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoaderAuthoriser.h>

@interface SPTDataLoaderAuthoriserMock : NSObject <SPTDataLoaderAuthoriser>

@property (nonatomic, assign, readonly) NSUInteger numberOfCallsToAuthoriseRequest;
@property (nonatomic, assign, readwrite, getter = isEnabled) BOOL enabled;

@end
