/*
 Copyright (c) 2015-2021 Spotify AB.

 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */
#import "PlaylistsViewModel.h"

#import <SPTDataLoader/SPTDataLoader.h>

static NSString * const PlaylistsViewModelMeURLString = @"https://api.spotify.com/v1/me";
static NSString * const PlaylistsViewModelSourceIdentifier = @"me";

@interface PlaylistsViewModel () <SPTDataLoaderDelegate>

@property (nonatomic, strong) SPTDataLoader *dataLoader;

@property (nonatomic, assign, readwrite, getter = isLoaded) BOOL loaded;

@property (nonatomic, strong) NSString *userID;
@property (nonatomic, strong, readonly) NSURL *playlistsURL;
@property (nonatomic, strong, readwrite) NSArray *items;

@end

@implementation PlaylistsViewModel

#pragma mark PlaylistsViewModel

- (instancetype)initWithDataLoader:(SPTDataLoader *)dataLoader
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _dataLoader = dataLoader;
    _dataLoader.delegate = self;
    
    return self;
}

- (void)load
{
    if (self.loaded) {
        return;
    }
    
    NSURL *meURL = [NSURL URLWithString:PlaylistsViewModelMeURLString];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:meURL
                                                        sourceIdentifier:PlaylistsViewModelSourceIdentifier];
    [self.dataLoader performRequest:request];
}

- (NSURL *)playlistsURL
{
    return [NSURL URLWithString:[NSString stringWithFormat:@"https://api.spotify.com/v1/users/%@/playlists", self.userID]];
}

- (void)setUserID:(NSString *)userID
{
    if ([_userID isEqualToString:userID]) {
        return;
    }
    
    _userID = userID;
    
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:self.playlistsURL
                                                        sourceIdentifier:PlaylistsViewModelSourceIdentifier];
    [self.dataLoader performRequest:request];
}

- (void)setItems:(NSArray *)items
{
    if ([_items isEqualToArray:items]) {
        return;
    }
    
    _items = items;
    
    self.loaded = YES;
}

- (void)setLoaded:(BOOL)loaded
{
    if (_loaded == loaded) {
        return;
    }
    
    _loaded = loaded;
    
    [self.delegate playlistsViewModelDidLoad:self];
}

#pragma mark SPTDataLoaderDelegate

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response
{
    if (response.body == nil) {
        return;
    }

    NSData *body = response.body;
    NSError *error = nil;
    NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:body
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:&error];
    if (!jsonDictionary) {
        NSLog(@"Error: %@", error);
        return;
    }
    
    if ([response.request.URL.absoluteString isEqualToString:PlaylistsViewModelMeURLString]) {
        self.userID = jsonDictionary[@"id"];
    } else if ([response.request.URL.absoluteString isEqualToString:(NSString * _Nonnull)self.playlistsURL.absoluteString]) {
        self.items = jsonDictionary[@"items"];
    }
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response
{
    
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request
{
    
}

@end
