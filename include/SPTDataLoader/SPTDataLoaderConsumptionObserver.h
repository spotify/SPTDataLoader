/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

@class SPTDataLoaderResponse;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SPTDataLoaderFetchType) {
    SPTDataLoaderFetchTypeUnknown,
    SPTDataLoaderFetchTypeNetwork,
    SPTDataLoaderFetchTypeLocalCache
};

/**
 The protocol an observer of the data loaders consumption must conform to
 */
@protocol SPTDataLoaderConsumptionObserver <NSObject>

/**
 Called when a request ends (either via cancel or receiving a server response
 @param response The response the request was ended with
 @param bytesDownloaded The amount of bytes downloaded
 @param bytesUploaded The amount of bytes uploaded
 */
- (void)endedRequestWithResponse:(SPTDataLoaderResponse *)response
                 bytesDownloaded:(int)bytesDownloaded
                   bytesUploaded:(int)bytesUploaded;

/**
 Called when a request ends (either via cancel or receiving a server response
 @param response The response the request was ended with
 @param fetchType Whether the resource was loaded from network or cache (if known).
 */
- (void)endedRequestWithResponse:(SPTDataLoaderResponse *)response fetchType:(SPTDataLoaderFetchType)fetchType;

@end

NS_ASSUME_NONNULL_END
