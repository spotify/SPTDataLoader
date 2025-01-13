/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

#import "SPTDataLoaderRequestResponseHandler.h"

@protocol SPTDataLoaderCancellationToken;
typedef id<SPTDataLoaderCancellationToken> (^SPTCancellationTokenCreator)(void);

@interface SPTDataLoaderRequestResponseHandlerDelegateMock : NSObject <SPTDataLoaderRequestResponseHandlerDelegate>

@property (nonatomic, strong) SPTDataLoaderRequest *lastRequestPerformed;
@property (nonatomic, strong) SPTDataLoaderRequest *lastRequestAuthorised;
@property (nonatomic, strong) SPTDataLoaderRequest *lastRequestFailed;
@property (nonatomic, strong, readwrite) SPTDataLoaderRequest *lastRequestCancelled;

@end
