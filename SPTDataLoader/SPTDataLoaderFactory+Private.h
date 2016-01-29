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
#import "SPTDataLoaderFactory.h"

#import "SPTDataLoaderRequestResponseHandler.h"

@protocol SPTDataLoaderRequestResponseHandlerDelegate;
@protocol SPTDataLoaderAuthoriser;

/**
 * The private API for the data loader factory for internal use in the SPTDataLoader library
 */
@interface SPTDataLoaderFactory (Private) <SPTDataLoaderRequestResponseHandler>

/**
 * Class constructor
 * @param requestResponseHandlerDelegate The private delegate to delegate request handling to
 * @param authorisers An NSArray of SPTDataLoaderAuthoriser objects for supporting different forms of authorisation
 */
+ (instancetype)dataLoaderFactoryWithRequestResponseHandlerDelegate:(id<SPTDataLoaderRequestResponseHandlerDelegate>)requestResponseHandlerDelegate
                                                        authorisers:(NSArray *)authorisers;

@end
