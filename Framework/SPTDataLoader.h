/*
 Copyright (c) 2015-2020 Spotify AB.

 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

#import <SPTDataLoader/SPTDataLoaderAuthoriser.h>
#import <SPTDataLoader/SPTDataLoaderCancellationToken.h>
#import <SPTDataLoader/SPTDataLoaderConsumptionObserver.h>
#import <SPTDataLoader/SPTDataLoaderDelegate.h>
#import <SPTDataLoader/SPTDataLoaderExponentialTimer.h>
#import <SPTDataLoader/SPTDataLoaderFactory.h>
#import <SPTDataLoader/SPTDataLoaderImplementation.h>
#import <SPTDataLoader/SPTDataLoaderRateLimiter.h>
#import <SPTDataLoader/SPTDataLoaderRequest.h>
#import <SPTDataLoader/SPTDataLoaderResolver.h>
#import <SPTDataLoader/SPTDataLoaderResponse.h>
#import <SPTDataLoader/SPTDataLoaderServerTrustPolicy.h>
#import <SPTDataLoader/SPTDataLoaderService.h>

//! Project version number for SPTDataLoader.
FOUNDATION_EXPORT double SPTDataLoaderVersionNumber;

//! Project version string for SPTDataLoader.
FOUNDATION_EXPORT const unsigned char SPTDataLoaderVersionString[];
