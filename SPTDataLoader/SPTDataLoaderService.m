#import "SPTDataLoaderService.h"

@implementation SPTDataLoaderService

#pragma mark SPTDataLoaderService

+ (instancetype)dataLoaderServiceWithUserAgent:(NSString *)userAgent
{
    return [[self alloc] initWithUserAgent:userAgent];
}

- (instancetype)initWithUserAgent:(NSString *)userAgent
{
    if (!(self = [super init])) {
        return nil;
    }
    
    return self;
}

- (SPTDataLoaderFactory *)createDataLoaderFactory
{
    return nil;
}

@end
