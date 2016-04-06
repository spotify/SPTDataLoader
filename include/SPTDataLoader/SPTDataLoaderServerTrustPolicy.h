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
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An object used to enforce certificate trust when presented with an
 * `NSURLAuthentificationChallenge` where the authentication method requires
 * `SecTrustRef` validation.
 */
@interface SPTDataLoaderServerTrustPolicy : NSObject

/**
 * Creates an server trust policy
 *
 * @param hostsAndCertificatePaths An NSDictionary where the key is the host and
 *                                 the value is an NSArray of paths to
 *                                 certificate files that will be used while
 *                                 validating a challenge.
 * @discussion The NSString key for host can include wildcards
 */
+ (instancetype)policyWithHostsAndCertificatePaths:(NSDictionary<NSString *, NSArray<NSString *> *> *)hostsAndCertificatePaths;

- (BOOL)validateChallenge:(NSURLAuthenticationChallenge *)challenge;

@end

NS_ASSUME_NONNULL_END
