/*
 * Copyright (c) 2015-2016 Spotify AB.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
#import "SPTDataLoaderResolver.h"

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
    if (!(self = [super init])) {
        return nil;
    }
    
    _resolverHost = [NSMutableDictionary new];
    _addresses = [NSHashTable weakObjectsHashTable];
    
    return self;
}

@end
