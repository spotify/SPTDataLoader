/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoaderResolver.h>

#import "SPTDataLoaderResolverAddress.h"

@interface SPTDataLoaderResolver ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSArray<SPTDataLoaderResolverAddress *> *> *resolverHost;
@property (nonatomic, strong) NSHashTable<SPTDataLoaderResolverAddress *> *addresses;

@end

@implementation SPTDataLoaderResolver

#pragma mark SPTDataLoaderResolver

- (NSString *)addressForHost:(NSString *)host
{
    @synchronized(self.resolverHost) {
        for (SPTDataLoaderResolverAddress *address in self.resolverHost[host]) {
            if (address.reachable) {
                return address.address;
            }
        }
    }
    return host;
}

- (void)setAddresses:(NSArray<NSString *> *)addresses forHost:(NSString *)host
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

    @synchronized(self.resolverHost) {
        self.resolverHost[host] = mutableAddress;
    }
}

- (void)markAddressAsUnreachable:(NSString *)address
{
    SPTDataLoaderResolverAddress *resolverAddress = [self resolverAddressForAddress:address];
    [resolverAddress failedToReach];
}

- (SPTDataLoaderResolverAddress *)resolverAddressForAddress:(NSString *)address
{
    NSArray *resolverAddresses = nil;
    @synchronized(self.addresses) {
        resolverAddresses = [self.addresses.allObjects copy];
    }
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
    self = [super init];
    if (self) {
        _resolverHost = [NSMutableDictionary new];
        _addresses = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

@end
