#import <SPTDataLoader/SPTDataLoaderResolver.h>

#import "SPTDataLoaderResolverAddress.h"

@interface SPTDataLoaderResolver ()

@property (nonatomic, strong) NSMutableDictionary *resolverHost;
@property (nonatomic, strong) NSHashTable *addresses;

@end

@implementation SPTDataLoaderResolver

#pragma mark SPTDataLoaderResolver

- (NSString *)addressForHost:(NSString *)host
{
    for (SPTDataLoaderResolverAddress *address in self.resolverHost[host]) {
        if (address.reachable) {
            return address.address;
        }
    }
    return host;
}

- (void)setAddresses:(NSArray *)addresses forHost:(NSString *)host
{
    NSMutableArray *mutableAddress = [NSMutableArray new];
    for (NSString *address in addresses) {
        SPTDataLoaderResolverAddress *resolverAddress = [self resolverAddressForAddress:address];
        if (!resolverAddress) {
            resolverAddress = [SPTDataLoaderResolverAddress dataLoaderResolverAddressWithAddress:address];
            [self.addresses addObject:resolverAddress];
        }
        [mutableAddress addObject:resolverAddress];
    }
    
    self.resolverHost[host] = mutableAddress;
}

- (void)markAddressAsUnreachable:(NSString *)address
{
    SPTDataLoaderResolverAddress *resolverAddress = [self resolverAddressForAddress:address];
    [resolverAddress failedToReach];
}

- (SPTDataLoaderResolverAddress *)resolverAddressForAddress:(NSString *)address
{
    NSArray *resolverAddresses = self.addresses.allObjects;
    for (SPTDataLoaderResolverAddress *resolverAddress in resolverAddresses) {
        if ([resolverAddress.address isEqualToString:address]) {
            return resolverAddress;
        }
    }
    return nil;
}

#pragma mark NSObject

- (instancetype)init
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _resolverHost = [NSMutableDictionary new];
    _addresses = [NSHashTable weakObjectsHashTable];
    
    return self;
}

@end
