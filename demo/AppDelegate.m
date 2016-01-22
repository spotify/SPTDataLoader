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

@import SPTDataLoader;

#import "SPTDataLoaderAuthoriserOAuth.h"
#import "NSString+OAuthBlob.h"
#import "PlaylistsViewController.h"
#import "PlaylistsViewModel.h"

static NSString *AppDelegateSourceIdentifier = @"app";

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
                                                               resolver:resolver
                                               customURLProtocolClasses:nil];
    self.factory = [self.service createDataLoaderFactoryWithAuthorisers:nil];
    self.loader = [self.factory createDataLoader];
    self.loader.delegate = self;
    return YES;
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
        SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:tokenURL
                                                            sourceIdentifier:AppDelegateSourceIdentifier];
        
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
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:playlistsViewController];
        [self.window.rootViewController presentViewController:navController animated:YES completion:nil];
    }
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"")
                                                                message:[response.error localizedDescription]
                                                         preferredStyle:UIAlertControllerStyleAlert];
    
    [ac addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                           style:UIAlertActionStyleCancel
                                         handler:nil]];
    
    [self.window.rootViewController presentViewController:ac animated:YES completion:nil];
    NSLog(@"Error: %@", response.error);
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request
{
}

@end
