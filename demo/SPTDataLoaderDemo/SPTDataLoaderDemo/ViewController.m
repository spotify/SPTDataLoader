#import "ViewController.h"

#import <SPTDataLoader/SPTDataLoaderFactory.h>
#import <SPTDataLoader/SPTDataLoaderService.h>
#import <SPTDataLoader/SPTDataLoader.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "AppDelegate.h"
#import "SPTDataLoaderAuthoriserDummy.h"

@interface ViewController () <SPTDataLoaderDelegate>

@property (nonatomic, strong) SPTDataLoaderFactory *factory;
@property (nonatomic, strong) SPTDataLoader *dataLoader;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    SPTDataLoaderAuthoriserDummy *authoriser = [SPTDataLoaderAuthoriserDummy new];
    self.factory = [appDelegate.service createDataLoaderFactoryWithAuthorisers:@[ authoriser ]];
    
    // Dispatch a request and see if we get something back
    self.dataLoader = [self.factory createDataLoader];
    self.dataLoader.delegate = self;
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
    [self.dataLoader performRequest:request];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response
{
    NSLog(@"Successful Response Received");
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response
{
    NSLog(@"Failed Response Received");
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request
{
    NSLog(@"Cancelled Request Received");
}

@end
