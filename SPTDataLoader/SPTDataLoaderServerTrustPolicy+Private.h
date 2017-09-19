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
#import "SPTDataLoaderServerTrustPolicy.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderServerTrustPolicy (Private)

/**
 * An NSDictionary where the key is the host and the value is an NSArray of
 * NSData representations of certificate files loaded upon instantiation that
 * will be used while validating a challenge.
 */
@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSData *> *> *trustedHostsAndCertificates;

/**
 * Looks up and returns pinned certificates as NSData objects for specified host.
 *
 * @param host The host domain to look up pinned certificates
 *
 * @return An array of certificate data for the host. If the host is not found/pinned, this value will be nil.
 */
- (nullable NSArray<NSData *> *)certificatesForHost:(NSString *)host;

/**
 * Internal method used for validating the provided `NSURLAuthenticationChallenge`
 * when validating through the public method -validateChallenge:
 *
 * @see -validateChallenge:
 *
 * @param trust The X.509 certificate trust of the server.
 * @param host  The host domain of the trust. If nil, the validation will return NO.
 *
 * @return Whether or not the server for host is trusted
 */
- (BOOL)validateWithTrust:(SecTrustRef)trust host:(nullable NSString *)host;

@end

NS_ASSUME_NONNULL_END
