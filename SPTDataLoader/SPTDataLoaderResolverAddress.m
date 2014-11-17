#import "SPTDataLoaderResolverAddress.h"

@interface SPTDataLoaderResolverAddress ()

@property (nonatomic, assign) NSTimeInterval stalePeriod;

@property (nonatomic, assign) CFAbsoluteTime lastFailedTime;

@end

@implementation SPTDataLoaderResolverAddress

#pragma mark SPTDataLoaderResolverAddress

- (BOOL)isReachable
{
    CFAbsoluteTime currentTime = CFAbsoluteTimeGetCurrent();
    NSTimeInterval deltaTime = currentTime - self.lastFailedTime;
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
    const NSTimeInterval SPTDataLoaderResolverAddressDefaultStalePeriodOneHour = 60.0 * 60.0;
    
    if (!(self = [super init])) {
        return nil;
    }
    
    _address = address;
    _stalePeriod = SPTDataLoaderResolverAddressDefaultStalePeriodOneHour;
    
    return self;
}

- (void)failedToReach
{
    self.lastFailedTime = CFAbsoluteTimeGetCurrent();
}

@end

