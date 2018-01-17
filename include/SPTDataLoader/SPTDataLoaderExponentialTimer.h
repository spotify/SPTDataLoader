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
#import <Foundation/Foundation.h>

#pragma mark - Default Jitter Values

/// The default jitter value which should give very good results most of the time.
FOUNDATION_EXPORT const double SPTDataLoaderExponentialTimerDefaultJitter;

#pragma mark - SPTDataLoaderExponentialTimer Interface

/**
 * Exponential timer with jitter for proper backoff handling in data transmissions.
 */
@interface SPTDataLoaderExponentialTimer : NSObject

#pragma mark Creating an Exponential Timer Object

/**
 * Create a timer with an initial time and maximum limit.
 *
 * @param initialTime The initial time to start counting the delay from.
 * @param maxTime Upper limit which shouldnt be exceeded when calculating a new delay value.
 */
+ (instancetype)exponentialTimerWithInitialTime:(NSTimeInterval)initialTime
                                        maxTime:(NSTimeInterval)maxTime;

/**
 * Create timer with initial time and max limit and user defined jitter
 *
 * @warning The default jitter gives very good results. If you stil want to use your own jitter
 * please perform verification of the delay values you get from the timer before putting the code
 * into production.
 *
 * @param initialTime The initial time to start counting the delay from.
 * @param maxTime Upper limit which shouldnt be exceeded when calculating a new delay value.
 * @param jitter Jitter value for calculating the delay.
 */
+ (instancetype)exponentialTimerWithInitialTime:(NSTimeInterval)initialTime
                                        maxTime:(NSTimeInterval)maxTime
                                         jitter:(double)jitter;

#pragma mark Accessing and Updating the Delay Value

/**
 * Returns the current delay value while also calculating the next one.
 *
 * @note This is the convenience method for `-timeInterval` and `-calculateNext`
 *
 * @return The current delay time interval.
 */
- (NSTimeInterval)timeIntervalAndCalculateNext;

/**
 * The current delay time interval.
 */
@property (nonatomic, assign, readonly) NSTimeInterval timeInterval;

/**
 * Calculate next delay time interval and return it.
 *
 * @return The time interval for the next delay.
 */
- (NSTimeInterval)calculateNext;

/*
 * Reset timer to initial state. After rset it can be reused.
 */
- (void)reset;

@end
