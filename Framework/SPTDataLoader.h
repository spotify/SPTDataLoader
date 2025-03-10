/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderAuthoriser.h>
#import <SPTDataLoader/SPTDataLoaderCancellationToken.h>
#import <SPTDataLoader/SPTDataLoaderConsumptionObserver.h>
#import <SPTDataLoader/SPTDataLoaderDelegate.h>
#import <SPTDataLoader/SPTDataLoaderExponentialTimer.h>
#import <SPTDataLoader/SPTDataLoaderFactory.h>
#import <SPTDataLoader/SPTDataLoaderImplementation.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderResolver.h>
#import <SPTDataLoader/SPTDataLoaderResponse.h>
#import <SPTDataLoader/SPTDataLoaderServerTrustPolicy.h>
#import <SPTDataLoader/SPTDataLoaderService.h>

//! Project version number for SPTDataLoader.
FOUNDATION_EXPORT double SPTDataLoaderVersionNumber;

//! Project version string for SPTDataLoader.
FOUNDATION_EXPORT const unsigned char SPTDataLoaderVersionString[];
