#import "SPTDataLoaderResponse.h"

@implementation SPTDataLoaderResponse

#pragma mark Private

+ (instancetype)dataLoaderResponseWithRequest:(SPTDataLoaderRequest *)request
{
    return [[self alloc] initWithRequest:request];
}

- (instancetype)initWithRequest:(SPTDataLoaderRequest *)request
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _request = request;
    
    return self;
}

@end
