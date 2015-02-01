#import "ViewController.h"

#import <SPTDataLoader/SPTDataLoaderFactory.h>
#import <SPTDataLoader/SPTDataLoaderService.h>
#import <SPTDataLoader/SPTDataLoader.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logInButtonTouchedUpInside:(id)sender
{
    NSURLComponents *accountsComponents = [NSURLComponents new];
    accountsComponents.scheme = @"https";
    accountsComponents.host = @"accounts.spotify.com";
    accountsComponents.path = @"/authorize";
    
    NSURLQueryItem *responseTypeQueryItem = [NSURLQueryItem queryItemWithName:@"response_type" value:@"code"];
    NSURLQueryItem *clientIDQueryItem = [NSURLQueryItem queryItemWithName:@"client_id" value:@"c0af246cb182480cb614d27026bfc9c3"];
    NSURLQueryItem *scopeQueryItem = [NSURLQueryItem queryItemWithName:@"scope" value:@"playlist-read-private"];
    NSURLQueryItem *redirectURIQueryItem = [NSURLQueryItem queryItemWithName:@"redirect_uri" value:@"sptdataloaderdemo://login"];
    NSURLQueryItem *stateQueryItem = [NSURLQueryItem queryItemWithName:@"state" value:@"AAAAAAAAAAAAAAAA"];
    
    accountsComponents.queryItems = @[ responseTypeQueryItem, clientIDQueryItem, scopeQueryItem, redirectURIQueryItem, stateQueryItem ];
    
    [[UIApplication sharedApplication] openURL:accountsComponents.URL];
}

@end
