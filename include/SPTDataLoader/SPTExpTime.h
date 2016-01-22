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

FOUNDATION_EXPORT const double kDefaultJitter;

/**
 * Exponential timer with jitter for proper backoff handling in data transmissions
 */
@interface SPTExpTime : NSObject

/**
 * Create timer with initial time and max limit
 * @param time0 initial time to start counting delay from
 * @param maxTime Upper limit which shouldnt be exceeded when calculatin new delay value
 */
+ (instancetype)expTimeWithInitialTime:(NSTimeInterval)time0 maxTime:(NSTimeInterval)maxTime;

/**
 * Create timer with initial time and max limit and user defined jitter
 * Default jitter gives vary good results. If you stil want to use your own jitter please do verification of delay values
 * you get from the timer once before puttin core into production.
 * @param time0 initial time to start counting delay from
 * @param maxTime Upper limit which shouldnt be exceeded when calculatin new delay value
 * @param jitter Jitter value for calculated delay
 */
+ (instancetype)expTimeWithInitialTime:(NSTimeInterval)time0 maxTime:(NSTimeInterval)maxTime jitter:(double)jitter;

/**
 * Return current delay value and calculate next
 * This is the convenience method for below 
 */
- (NSTimeInterval)timeIntervalAndCalculateNext;

/**
 * Retur current time interval
 */
- (NSTimeInterval)timeInterval;

/*
 * Calculate next delay and return it
 */
- (NSTimeInterval)calculateNext;

/*
 * Reset timer to initial state. After rset it can be reused.
 */
- (void)reset;

@end
