/*
 * Copyright (c) 2015-2017 Spotify AB.
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
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An object for keeping track of IP addresses to use for hosts
 */
@interface SPTDataLoaderResolver : NSObject

/**
 * Find a known valid address for the host
 * @param host The host to resolve
 */
- (NSString *)addressForHost:(NSString *)host;
/**
 * Set a list of valid addresses for the host
 * @param addresses An NSArray of NSString objects denoting an address
 * @param host The host tied to these addresses
 */
- (void)setAddresses:(NSArray<NSString *> *)addresses forHost:(NSString *)host;
/**
 * Mark an address as unreachable
 * @param address The address that has become unreachable
 */
- (void)markAddressAsUnreachable:(NSString *)address;

@end

NS_ASSUME_NONNULL_END
