/*
 Copyright (c) 2015-2021 Spotify AB.

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
#import "SPTDataLoaderCancellationTokenImplementation.h"

NS_ASSUME_NONNULL_BEGIN

@interface SPTDataLoaderCancellationTokenImplementation ()


@property (nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;

@end

@implementation SPTDataLoaderCancellationTokenImplementation

#pragma mark SPTDataLoaderCancellationTokenImplementation

+ (instancetype)cancellationTokenImplementationWithDelegate:(id<SPTDataLoaderCancellationTokenDelegate>)delegate
                                               cancelObject:(nullable id)cancelObject
{
    return [[self alloc] initWithDelegate:delegate cancelObject:cancelObject];
}

- (instancetype)initWithDelegate:(id<SPTDataLoaderCancellationTokenDelegate>)delegate cancelObject:(nullable id)cancelObject
{
    self = [super init];
    if (self) {
        _delegate = delegate;
        _objectToCancel = cancelObject;
    }
    
    return self;
}

#pragma mark SPTDataLoaderCancellationToken

@synthesize cancelled = _cancelled;
@synthesize delegate = _delegate;
@synthesize objectToCancel = _objectToCancel;

- (void)cancel
{
    if (self.cancelled) {
        return;
    }
    
    [self.delegate cancellationTokenDidCancel:self];
    
    self.cancelled = YES;
}

@end

NS_ASSUME_NONNULL_END
