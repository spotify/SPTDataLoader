/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoader.h>

@interface SPTDataLoaderAuthoriserOAuth : NSObject <SPTDataLoaderAuthoriser>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                 dataLoaderFactory:(SPTDataLoaderFactory *)dataLoaderFactory NS_DESIGNATED_INITIALIZER;

@end
