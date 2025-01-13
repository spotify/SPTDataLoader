/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoaderConsumptionObserver.h>

@interface SPTDataLoaderConsumptionObserverMock : NSObject <SPTDataLoaderConsumptionObserver>

@property (nonatomic, assign) NSInteger numberOfCallsToEndedRequest;
@property (nonatomic, strong, readwrite, nullable) dispatch_block_t endedRequestCallback;
@property (nonatomic, assign, readwrite) NSInteger lastBytesDownloaded;

@end
