#import "SPTDataLoaderAuthoriserMock.h"

@interface SPTDataLoaderAuthoriserMock ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfCallsToAuthoriseRequest;

@end

@implementation SPTDataLoaderAuthoriserMock

@synthesize identifier = _identifier;
@synthesize delegate = _delegate;

- (instancetype)init
{
    if (!(self = [super init])) {
        return nil;
    }

    _enabled = YES;

    return self;
}

- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request
{
    return self.enabled;
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
    self.numberOfCallsToAuthoriseRequest++;
    [self.delegate dataLoaderAuthoriser:self authorisedRequest:request];
}

- (void)requestFailedAuthorisation:(SPTDataLoaderRequest *)request
{
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self.class new];
}

- (void)refresh
{
    
}

@end
