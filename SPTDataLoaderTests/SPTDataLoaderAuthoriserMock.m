#import "SPTDataLoaderAuthoriserMock.h"

@interface SPTDataLoaderAuthoriserMock ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfCallsToAuthoriseRequest;

@end

@implementation SPTDataLoaderAuthoriserMock

@synthesize identifier = _identifier;
@synthesize delegate = _delegate;

- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request
{
    return YES;
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
