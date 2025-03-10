/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <UIKit/UIKit.h>

@class SPTDataLoaderService;
@class SPTDataLoaderFactory;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readonly) SPTDataLoaderService *service;
@property (nonatomic, strong, readonly) SPTDataLoaderFactory *factory;

@end
