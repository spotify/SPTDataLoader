#import "SPTDataLoader.h"

#import "SPTDataLoader+Private.h"

@interface SPTDataLoader ()

@property (nonatomic, weak) id<SPTDataLoaderPrivateDelegate> privateDelegate;

@end

@implementation SPTDataLoader

#pragma mark SPTDataLoader

- (id<SPTCancellationToken>)performRequest:(SPTDataLoaderRequest *)request
{
    return nil;
}

- (void)cancelAllLoads
{
}

@end
