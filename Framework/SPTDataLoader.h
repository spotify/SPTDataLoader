/*
 * Copyright (c) 2015-2018 Spotify AB.
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

#import "SPTDataLoaderAuthoriser.h"
#import "SPTDataLoaderCancellationToken.h"
#import "SPTDataLoaderConsumptionObserver.h"
#import "SPTDataLoaderDelegate.h"
#import "SPTDataLoaderExponentialTimer.h"
#import "SPTDataLoaderFactory.h"
#import "SPTDataLoaderImplementation.h"
#import "SPTDataLoaderRateLimiter.h"
#import "SPTDataLoaderRequest.h"
#import "SPTDataLoaderResolver.h"
#import "SPTDataLoaderResponse.h"
#import "SPTDataLoaderServerTrustPolicy.h"
#import "SPTDataLoaderService.h"

//! Project version number for SPTDataLoader.
FOUNDATION_EXPORT double SPTDataLoaderVersionNumber;

//! Project version string for SPTDataLoader.
FOUNDATION_EXPORT const unsigned char SPTDataLoaderVersionString[];
