#import "SPTDataLoaderFactory.h"

#import "SPTDataLoader+Private.h"

@interface SPTDataLoaderFactory () <SPTDataLoaderPrivateDelegate>

@property (nonatomic, weak, readonly) id<SPTDataLoaderPrivateDelegate> privateDelegate;

@end

@implementation SPTDataLoaderFactory

#pragma mark Private

+ (instancetype)dataLoaderFactoryWithPrivateDelegate:(id<SPTDataLoaderPrivateDelegate>)privateDelegate
{
    return [[self alloc] initWithPrivateDelegate:privateDelegate];
}

- (instancetype)initWithPrivateDelegate:(id<SPTDataLoaderPrivateDelegate>)privateDelegate
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _privateDelegate = privateDelegate;
    
    return self;
}

#pragma mark SPTDataLoaderFactory

- (SPTDataLoader *)createDataLoader
{
    return [SPTDataLoader dataLoaderWithPrivateDelegate:self];
}

#pragma mark SPTDataLoaderPrivateDelegate

- (id<SPTCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
{
    return [self.privateDelegate performRequest:request];
}

@end
