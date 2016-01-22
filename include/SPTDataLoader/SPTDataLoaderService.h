/*
 * Copyright (c) 2015 Spotify AB.
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

@class SPTDataLoaderFactory;
@class SPTDataLoaderRateLimiter;
@class SPTDataLoaderResolver;

@protocol SPTDataLoaderConsumptionObserver;

/**
 * The service used for creating data loader factories and providing application wide rate limiting to services
 */
@interface SPTDataLoaderService : NSObject

/**
 * Whether all certificates are allowed (e.g. broken certificates don't cause closed connections)
 * @discussion By default this is NO. You should only turn this on if you are certain it will not be on in release
 * builds.
 * @warning This will trigger an assert if all certificates are allowed on release builds.
 */
@property (nonatomic, assign, readwrite, getter = isAllCertificatesAllowed) BOOL allCertificatesAllowed;

/**
 * Class constructor
 * @param userAgent The user agent to report as when making HTTP requests
 * @param rateLimiter The limiter for limiting requests per second on a per service basis
 * @param resolver The resolver for rerouting requests to different IP addresses
 * @param customURLProtocolClasses Array of NSURLProtocol Class objects that you want
 *                                 to use for this DataLoaderService. May be nil.
 */
+ (instancetype)dataLoaderServiceWithUserAgent:(NSString *)userAgent
                                   rateLimiter:(SPTDataLoaderRateLimiter *)rateLimiter
                                      resolver:(SPTDataLoaderResolver *)resolver
                      customURLProtocolClasses:(NSArray *)customURLProtocolClasses;

/**
 * Creates a data loader factory
 * @param authorisers An NSArray of SPTDataLoaderAuthoriser objects for supporting different forms of authorisation
 */
- (SPTDataLoaderFactory *)createDataLoaderFactoryWithAuthorisers:(NSArray *)authorisers;
/**
 * Adds a consumption observer
 * @param consumptionObserver The consumption observer to add to the service
 * @param queue The queue to call the consumption observer on
 * @warning This will have a weak reference to the consumption observer
 */
- (void)addConsumptionObserver:(id<SPTDataLoaderConsumptionObserver>)consumptionObserver on:(dispatch_queue_t)queue;
/**
 * Removes a consumption observer
 * @param consumptionObserver The consumption observer to remove from the service
 */
- (void)removeConsumptionObserver:(id<SPTDataLoaderConsumptionObserver>)consumptionObserver;

@end
