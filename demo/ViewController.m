/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "ViewController.h"
#import "ClientKeys.h"

#import <SPTDataLoader/SPTDataLoader.h>

@implementation ViewController

- (IBAction)logInButtonTouchedUpInside:(id)sender
{
    NSURLComponents *accountsComponents = [NSURLComponents new];
    accountsComponents.scheme = @"https";
    accountsComponents.host = @"accounts.spotify.com";
    accountsComponents.path = @"/authorize";

    NSURLQueryItem *responseTypeQueryItem = [NSURLQueryItem queryItemWithName:@"response_type" value:@"code"];
    NSURLQueryItem *clientIDQueryItem = [NSURLQueryItem queryItemWithName:@"client_id" value:SPOTIFY_CLIENT_ID];
    NSURLQueryItem *scopeQueryItem = [NSURLQueryItem queryItemWithName:@"scope" value:@"playlist-read-private"];
    NSURLQueryItem *redirectURIQueryItem = [NSURLQueryItem queryItemWithName:@"redirect_uri" value:SPOTIFY_REDIRECT_URI];
    NSURLQueryItem *stateQueryItem = [NSURLQueryItem queryItemWithName:@"state" value:@"AAAAAAAAAAAAAAAA"];

    accountsComponents.queryItems = @[ responseTypeQueryItem, clientIDQueryItem, scopeQueryItem, redirectURIQueryItem, stateQueryItem ];

    NSURL *URL = accountsComponents.URL;
    [[UIApplication sharedApplication] openURL:URL options:@{} completionHandler:nil];
}

@end
