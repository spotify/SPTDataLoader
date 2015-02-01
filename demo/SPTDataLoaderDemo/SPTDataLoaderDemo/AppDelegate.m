/*
 * Copyright (c) 2015 Spotify AB.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
#import "AppDelegate.h"

#import <SPTDataLoader/SPTDataLoader.h>

#import "SPTDataLoaderAuthoriserOAuth.h"
#import "NSString+OAuthBlob.h"
#import "PlaylistsViewController.h"
#import "PlaylistsViewModel.h"

@interface AppDelegate () <SPTDataLoaderDelegate>

@property (nonatomic, strong, readwrite) SPTDataLoaderService *service;
@property (nonatomic, strong, readwrite) SPTDataLoaderFactory *factory;

@property (nonatomic, strong) SPTDataLoader *loader;
@property (nonatomic, strong) SPTDataLoaderFactory *oauthFactory;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    SPTDataLoaderRateLimiter *rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:10.0];
    SPTDataLoaderResolver *resolver = [SPTDataLoaderResolver new];
    self.service = [SPTDataLoaderService dataLoaderServiceWithUserAgent:@"Spotify-Demo"
                                                            rateLimiter:rateLimiter
                                                               resolver:resolver];
    self.factory = [self.service createDataLoaderFactoryWithAuthorisers:nil];
    self.loader = [self.factory createDataLoader];
    self.loader.delegate = self;
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    if ([components.scheme isEqualToString:@"sptdataloaderdemo"] && [components.host isEqualToString:@"login"]) {
        NSArray *queryItems = components.queryItems;
        
        NSString *code = nil;
        NSString *state = nil;
        for (NSURLQueryItem *queryItem in queryItems) {
            if ([queryItem.name isEqualToString:@"code"]) {
                code = queryItem.value;
            } else if ([queryItem.name isEqualToString:@"state"]) {
                state = queryItem.value;
            }
        }
        
        if (!code || !state) {
            return NO;
        }
        
        NSURL *tokenURL = [NSURL URLWithString:@"https://accounts.spotify.com/api/token"];
        SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:tokenURL];
        
        request.method = SPTDataLoaderRequestMethodPost;
        NSDictionary *tokenBodyDictionary = @{ @"grant_type" : @"authorization_code",
                                               @"code" : code,
                                               @"redirect_uri" : @"sptdataloaderdemo://login" };
        NSMutableArray *tokenBodyParameters = [NSMutableArray new];
        for (NSString *tokenBodyKey in tokenBodyDictionary) {
            NSString *tokenBodyParameter = [@[ tokenBodyKey, tokenBodyDictionary[tokenBodyKey] ] componentsJoinedByString:@"="];
            [tokenBodyParameters addObject:tokenBodyParameter];
        }
        NSString *tokenBodyString = [tokenBodyParameters componentsJoinedByString:@"&"];
        NSData *tokenBody = [tokenBodyString dataUsingEncoding:NSUTF8StringEncoding];
        
        request.body = tokenBody;
        
        NSString *basicAuthorisation = [@"Basic " stringByAppendingString:[NSString spt_OAuthBlob]];
        [request addValue:basicAuthorisation forHeader:@"Authorization"];
        
        [self.loader performRequest:request];
        
        return YES;
    }
    
    return NO;
}

#pragma mark SPTDataLoaderDelegate

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response
{
    NSError *error = nil;
    NSDictionary *oauthTokenDictionary = [NSJSONSerialization JSONObjectWithData:response.body
                                                                         options:NSJSONReadingAllowFragments
                                                                           error:&error];
    if (!oauthTokenDictionary) {
        NSLog(@"Error %@" ,error);
    } else {
        id<SPTDataLoaderAuthoriser> oauthAuthoriser = [[SPTDataLoaderAuthoriserOAuth alloc] initWithDictionary:oauthTokenDictionary
                                                                                             dataLoaderFactory:self.factory];
        self.oauthFactory = [self.service createDataLoaderFactoryWithAuthorisers:@[ oauthAuthoriser ]];
        
        PlaylistsViewModel *model = [[PlaylistsViewModel alloc] initWithDataLoader:[self.oauthFactory createDataLoader]];
        PlaylistsViewController *playlistsViewController = [[PlaylistsViewController alloc] initWithModel:model];
        [self.window.rootViewController presentViewController:playlistsViewController animated:YES completion:nil];
    }
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response
{
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request
{
}

@end
