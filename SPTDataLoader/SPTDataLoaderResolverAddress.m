#import "SPTDataLoaderResolverAddress.h"

@interface SPTDataLoaderResolverAddress ()

@property (nonatomic ,assign) CFAbsoluteTime stalePeriod;

@property (nonatomic, assign) CFAbsoluteTime lastFailedTime;

@end

@implementation SPTDataLoaderResolverAddress

#pragma mark SPTDataLoaderResolverAddress

- (BOOL)isReachable
{
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    CFAbsoluteTime deltaTime = currentTime - self.lastFailedTime;
    if (deltaTime < 0.0) {
        return YES;
    }
    
    return deltaTime > self.stalePeriod;
}

+ (instancetype)dataLoaderResolverAddressWithAddress:(NSString *)address
{
    return [[self alloc] initWithAddress:address];
}

- (instancetype)initWithAddress:(NSString *)address
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _address = address;
    _stalePeriod = 60.0 * 60.0;
    
    return self;
}

- (void)failedToReach
{
    self.lastFailedTime = CFAbsoluteTimeGetCurrent();
}

@end

