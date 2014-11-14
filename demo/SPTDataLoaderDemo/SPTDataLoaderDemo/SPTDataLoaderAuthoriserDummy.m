#import "SPTDataLoaderAuthoriserDummy.h"

@implementation SPTDataLoaderAuthoriserDummy

- (id)init
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _identifier = @"Dummy-Authoriser";
    
    return self;
}

@synthesize identifier = _identifier;
@synthesize delegate = _delegate;

- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request
{
    return YES;
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.delegate dataLoaderAuthoriser:self authorisedRequest:request];
    });
}

- (id)copyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [self.class new];
    copy.delegate = self.delegate;
    return copy;
}

@end
