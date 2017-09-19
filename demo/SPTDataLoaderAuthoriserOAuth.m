/*
 * Copyright (c) 2015-2017 Spotify AB.
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
#import "SPTDataLoaderAuthoriserOAuth.h"

#import "NSString+OAuthBlob.h"

static NSString *SPTDataLoaderAuthoriserOAuthSourceIdentifier = @"auth";
static NSString *SPTDataLoaderAuthoriserHeaderValuesJoiner = @" ";
static NSString *SPTDataLoaderAuthoriserHeader = @"Authorization";

@interface SPTDataLoaderAuthoriserOAuth () <SPTDataLoaderDelegate>

@property (nonatomic, strong) SPTDataLoader *dataLoader;
@property (nonatomic, strong) SPTDataLoaderFactory *dataLoaderFactory;

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *tokenType;
@property (nonatomic, assign) NSTimeInterval expiresIn;
@property (nonatomic, strong) NSString *refreshToken;
@property (nonatomic, assign) CFAbsoluteTime lastRefreshTime;
@property (nonatomic, strong) NSMutableArray *pendingRequests;

@property (nonatomic, assign, readonly, getter = isTokenValid) BOOL tokenValid;

@end

@implementation SPTDataLoaderAuthoriserOAuth

#pragma mark SPTDataLoaderAuthoriserOAuth

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                 dataLoaderFactory:(SPTDataLoaderFactory *)dataLoaderFactory
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _dataLoaderFactory = dataLoaderFactory;
    _dataLoader = [dataLoaderFactory createDataLoader];
    _dataLoader.delegate = self;
    
    [self saveTokenDictionary:dictionary];
    _pendingRequests = [NSMutableArray new];
    
    return self;
}

- (BOOL)isTokenValid
{
    return self.accessToken.length
        && self.tokenType.length
        && (CFAbsoluteTimeGetCurrent() - self.lastRefreshTime) < self.expiresIn;
}

- (void)authorisePendingRequest:(SPTDataLoaderRequest *)request
{
    NSArray *authorizationValueArray = @[ self.tokenType, self.accessToken ];
    [request addValue:[authorizationValueArray componentsJoinedByString:SPTDataLoaderAuthoriserHeaderValuesJoiner] forHeader:SPTDataLoaderAuthoriserHeader];
    [self.delegate dataLoaderAuthoriser:self authorisedRequest:request];
}

- (void)saveTokenDictionary:(NSDictionary *)tokenDictionary
{
    self.accessToken = tokenDictionary[@"access_token"];
    self.tokenType = tokenDictionary[@"token_type"];
    self.expiresIn = [tokenDictionary[@"expires_in"] doubleValue];
    if (tokenDictionary[@"refresh_token"]) {
        self.refreshToken = tokenDictionary[@"refresh_token"];
    }
    self.lastRefreshTime = CFAbsoluteTimeGetCurrent();
}

#pragma mark SPTDataLoaderAuthoriser

@synthesize delegate = _delegate;

- (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request
{
    // Only require authorisation if we are accessing api.spotify.com over https
    return [request.URL.host isEqualToString:@"api.spotify.com"] && [request.URL.scheme isEqualToString:@"https"];
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
    if (self.tokenValid) {
        [self authorisePendingRequest:request];
    } else {
        @synchronized(self.pendingRequests) {
            [self.pendingRequests addObject:request];
        }
        [self refresh];
    }
}

- (void)requestFailedAuthorisation:(SPTDataLoaderRequest *)request
{
    self.accessToken = nil;
    self.expiresIn = 0.0;
    self.tokenType = nil;
}

- (void)refresh
{
    NSURL *accountsURL = [NSURL URLWithString:@"https://accounts.spotify.com/api/token"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:accountsURL
                                                        sourceIdentifier:SPTDataLoaderAuthoriserOAuthSourceIdentifier];
    
    NSArray *authorisationHeaderValues = @[ @"Basic", [NSString spt_OAuthBlob] ];
    [request addValue:[authorisationHeaderValues componentsJoinedByString:SPTDataLoaderAuthoriserHeaderValuesJoiner] forHeader:SPTDataLoaderAuthoriserHeader];
    [self.dataLoader performRequest:request];
}

#pragma mark SPTDataLoaderDelegate

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response
{
    if (response.body == nil) {
        return;
    }

    NSData *body = response.body;
    NSError *error = nil;
    NSDictionary *tokenDictionary = [NSJSONSerialization JSONObjectWithData:body
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&error];
    
    @synchronized(self.pendingRequests) {
        if (!tokenDictionary) {
            for (SPTDataLoaderRequest *pendingRequest in self.pendingRequests) {
                [self.delegate dataLoaderAuthoriser:self didFailToAuthoriseRequest:pendingRequest withError:error];
            }
            return;
        }
        
        [self saveTokenDictionary:tokenDictionary];
        for (SPTDataLoaderRequest *pendingRequest in self.pendingRequests) {
            [self authorisePendingRequest:pendingRequest];
        }
    }
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response
{
    @synchronized(self.pendingRequests) {
        for (SPTDataLoaderRequest *pendingRequest in self.pendingRequests) {
            NSError *error = response.error;
            [self.delegate dataLoaderAuthoriser:self didFailToAuthoriseRequest:pendingRequest withError:error];
        }
    }
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request
{
    
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    NSDictionary *tokenDictionary = @{ @"access_token" : self.accessToken,
                                       @"token_type" : self.tokenType,
                                       @"expires_in" : @(self.expiresIn),
                                       @"refresh_token" : self.refreshToken };
    SPTDataLoaderAuthoriserOAuth *authoriserCopy = [[SPTDataLoaderAuthoriserOAuth alloc] initWithDictionary:tokenDictionary
                                                                                          dataLoaderFactory:self.dataLoaderFactory];
    return authoriserCopy;
}

#pragma mark NSObject

- (instancetype)init
{
    return [self initWithDictionary:nil dataLoaderFactory:nil];
}

@end
