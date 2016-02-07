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
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 * An object for tracking a resolver addresses reachability
 */
@interface SPTDataLoaderResolverAddress : NSObject

/**
 * The IP address
 */
@property (nonatomic, strong) NSString *address;
/**
 * Whether the IP address should currently be considered reachable
 */
@property (nonatomic, assign, readonly, getter = isReachable) BOOL reachable;

/**
 * Class constructor
 * @param address The IP address to represent
 */
+ (instancetype)dataLoaderResolverAddressWithAddress:(NSString *)address;

/**
 * Call when this address has failed to be contacted
 */
- (void)failedToReach;

@end

NS_ASSUME_NONNULL_END
