/*
 Copyright (c) 2015-2018 Spotify AB.

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
#import "SPTDataLoaderExponentialTimer.h"

#import <math.h>
#import <stdlib.h>


#pragma mark - Default Values

static const double SPTDataLoaderExponentialTimerDefaultGrow = M_E;
const double SPTDataLoaderExponentialTimerDefaultJitter = 0.11304999836;


#pragma mark - SPTDataLoaderExponentialTimer Private Interface

@interface SPTDataLoaderExponentialTimer ()

@property (nonatomic, assign, readwrite) NSTimeInterval timeInterval;
@property (nonatomic, assign, readonly) NSTimeInterval maxTime;
@property (nonatomic, assign, readonly) NSTimeInterval initialTime;

@property (nonatomic, assign, readonly) double jitter;
@property (nonatomic, assign, readonly) double growFactor;

@end


#pragma mark - SPTDataLoaderExponentialTimer Implementation

@implementation SPTDataLoaderExponentialTimer

#pragma mark Creating an Exponential Timer Object

+ (instancetype)exponentialTimerWithInitialTime:(NSTimeInterval)initialTime
                                        maxTime:(NSTimeInterval)maxTime
{
    return [self exponentialTimerWithInitialTime:initialTime maxTime:maxTime jitter:SPTDataLoaderExponentialTimerDefaultJitter];
}

+ (instancetype)exponentialTimerWithInitialTime:(NSTimeInterval)initialTime
                                        maxTime:(NSTimeInterval)maxTime
                                         jitter:(double)jitter
{
    return [[self alloc] initWithInitialTime:initialTime
                                     maxTime:maxTime
                                  growFactor:SPTDataLoaderExponentialTimerDefaultGrow
                                      jitter:jitter];
}

- (instancetype)initWithInitialTime:(NSTimeInterval)initialTime
                            maxTime:(NSTimeInterval)maxTime
                         growFactor:(double)growFactor
                             jitter:(double)jitter
{
    self = [super init];
    if (self) {
        _initialTime = initialTime;
        _timeInterval = initialTime;
        _maxTime = maxTime;
        _growFactor = growFactor;
        _jitter = jitter;
    }
    return self;
}

#pragma mark Accessing and Updating the Delay Value

- (void)reset
{
    self.timeInterval = self.initialTime;
}

- (NSTimeInterval)calculateNext
{
    NSTimeInterval nextTime = self.timeInterval * self.growFactor;
    
    if (nextTime > self.maxTime) {
        nextTime = self.maxTime;
    }
    
    if (self.jitter < 0.0001) {
        self.timeInterval = nextTime;
    } else {
        const double sigma = self.jitter * nextTime;
        self.timeInterval = [self.class normalWithMu:nextTime sigma:sigma];
    }
    
    if (self.timeInterval > self.maxTime) {
        self.timeInterval = self.maxTime;
    }
    
    return self.timeInterval;
}

- (NSTimeInterval)timeIntervalAndCalculateNext
{
    const NSTimeInterval timeInterval = self.timeInterval;
    [self calculateNext];

    return timeInterval;
}

#pragma mark Calculating Exponential Backoff

#define EXPT_MODULO ((u_int32_t)RAND_MAX)
#define EXPT_MODULO_F64 ((double)(EXPT_MODULO))
NS_INLINE double SPTExptRandom()
{
    // We need [0, 1) interval
    return arc4random_uniform(EXPT_MODULO);
}

+ (NSTimeInterval)normalWithMu:(double)mu sigma:(double)sigma
{
    /**
     Uses Kinderman and Monahan method. Reference: Kinderman,
     A.J. and Monahan, J.F., "Computer generation of random
     variables using the ratio of uniform deviates", ACM Trans
     Math Software, 3, (1977), pp257-260.
    */

    const int attempts = 20;
    for (int i = 0; i < attempts; ++i) {
        const double a = SPTExptRandom() / EXPT_MODULO_F64;
        const double b = 1.0 - (SPTExptRandom() / EXPT_MODULO_F64);
        const double c = 1.7155277699214135 * (a - 0.5) / b;
        const double d = c * c / 4.0;
        
        if (d <= -1.0 * log(b)) {
            return mu + c * sigma;
        }
    }
    
    return mu + 2.0 * sigma * (SPTExptRandom() / EXPT_MODULO_F64);
}

@end
