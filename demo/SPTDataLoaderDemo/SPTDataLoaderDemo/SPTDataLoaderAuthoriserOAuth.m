#import "SPTDataLoaderAuthoriserOAuth.h"

#import "NSString+OAuthBlob.h"

@interface SPTDataLoaderAuthoriserOAuth () <SPTDataLoaderDelegate>

@property (nonatomic, strong) SPTDataLoader *dataLoader;
@property (nonatomic, strong) SPTDataLoaderFactory *dataLoaderFactory;

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *tokenType;
@property (nonatomic, assign) NSTimeInterval expiresIn;
@property (nonatomic, strong) NSString *refreshToken;
@property (nonatomic, assign) CFAbsoluteTime lastRefreshTime;
@property (nonatomic, strong) NSMutableArray *pendingRequests;

@property (nonatomic, assign, readonly, getter = isTokenValid) BOOL tokenValid;

@end

@implementation SPTDataLoaderAuthoriserOAuth

#pragma mark SPTDataLoaderAuthoriserOAuth

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                 dataLoaderFactory:(SPTDataLoaderFactory *)dataLoaderFactory
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _dataLoaderFactory = dataLoaderFactory;
    _dataLoader = [dataLoaderFactory createDataLoader];
    _dataLoader.delegate = self;
    
    [self saveTokenDictionary:dictionary];
    _pendingRequests = [NSMutableArray new];
    
    return self;
}

- (BOOL)isTokenValid
{
    return self.accessToken.length
        && self.tokenType.length
        && (CFAbsoluteTimeGetCurrent() - self.lastRefreshTime) < self.expiresIn;
}

- (void)authorisePendingRequest:(SPTDataLoaderRequest *)request
{
    NSArray *authorizationValueArray = @[ self.tokenType, self.accessToken ];
    [request addValue:[authorizationValueArray componentsJoinedByString:@" "] forHeader:@"Authorization"];
    [self.delegate dataLoaderAuthoriser:self authorisedRequest:request];
}

- (void)saveTokenDictionary:(NSDictionary *)tokenDictionary
{
    self.accessToken = tokenDictionary[@"access_token"];
    self.tokenType = tokenDictionary[@"token_type"];
    self.expiresIn = [tokenDictionary[@"expires_in"] doubleValue];
    if (tokenDictionary[@"refresh_token"]) {
        self.refreshToken = tokenDictionary[@"refresh_token"];
    }
    self.lastRefreshTime = CFAbsoluteTimeGetCurrent();
}

#pragma mark SPTDataLoaderAuthoriser

@synthesize delegate = _delegate;

- (NSString *)identifier
{
    return NSStringFromClass(self.class);
}

- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request
{
    // Only require authorisation if we are accessing api.spotify.com over https
    return [request.URL.host isEqualToString:@"api.spotify.com"] && [request.URL.scheme isEqualToString:@"https"];
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
    if (self.tokenValid) {
        [self authorisePendingRequest:request];
    } else {
        @synchronized(self.pendingRequests) {
            [self.pendingRequests addObject:request];
        }
        [self refresh];
    }
}

- (void)requestFailedAuthorisation:(SPTDataLoaderRequest *)request
{
    self.accessToken = nil;
    self.expiresIn = 0.0;
    self.tokenType = nil;
}

- (void)refresh
{
    NSURL *accountsURL = [NSURL URLWithString:@"https://accounts.spotify.com/api/token"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:accountsURL];
    
    NSArray *authorisationHeaderValues = @[ @"Basic", [NSString spt_OAuthBlob] ];
    [request addValue:[authorisationHeaderValues componentsJoinedByString:@" "] forHeader:@"Authorization"];
    [self.dataLoader performRequest:request];
}

#pragma mark SPTDataLoaderDelegate

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response
{
    NSError *error = nil;
    NSDictionary *tokenDictionary = [NSJSONSerialization JSONObjectWithData:response.body
                                                                    options:NSJSONReadingAllowFragments
                                                                      error:&error];
    
    @synchronized(self.pendingRequests) {
        if (!tokenDictionary) {
            for (SPTDataLoaderRequest *pendingRequest in self.pendingRequests) {
                [self.delegate dataLoaderAuthoriser:self didFailToAuthoriseRequest:pendingRequest withError:error];
            }
            return;
        }
        
        [self saveTokenDictionary:tokenDictionary];
        for (SPTDataLoaderRequest *pendingRequest in self.pendingRequests) {
            [self authorisePendingRequest:pendingRequest];
        }
    }
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveErrorResponse:(SPTDataLoaderResponse *)response
{
    @synchronized(self.pendingRequests) {
        for (SPTDataLoaderRequest *pendingRequest in self.pendingRequests) {
            [self.delegate dataLoaderAuthoriser:self didFailToAuthoriseRequest:pendingRequest withError:response.error];
        }
    }
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didCancelRequest:(SPTDataLoaderRequest *)request
{
    
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    NSDictionary *tokenDictionary = @{ @"access_token" : self.accessToken,
                                       @"token_type" : self.tokenType,
                                       @"expires_in" : @(self.expiresIn),
                                       @"refresh_token" : self.refreshToken };
    SPTDataLoaderAuthoriserOAuth *authoriserCopy = [[SPTDataLoaderAuthoriserOAuth alloc] initWithDictionary:tokenDictionary
                                                                                          dataLoaderFactory:self.dataLoaderFactory];
    return authoriserCopy;
}

@end
