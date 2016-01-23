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
#import "SPTDataLoaderExponentialTimer.h"

@import Darwin.C.math;
@import Darwin.C.stdlib;

static const double kDefaultGrow = M_E;
const double kDefaultJitter = 0.11304999836;

@interface SPTDataLoaderExponentialTimer ()

@property (nonatomic, assign) NSTimeInterval currTime;
@property (nonatomic, assign) double growFactor;
@property (nonatomic, assign) NSTimeInterval maxTime;
@property (nonatomic, assign) double jitter;
@property (nonatomic, assign) NSTimeInterval initialTime;

@end

@implementation SPTDataLoaderExponentialTimer
{
    double _prevSigma;
}

+ (instancetype)expTimeWithInitialTime:(NSTimeInterval)time0
                               maxTime:(NSTimeInterval)maxTime
                            growFactor:(double)growFactor
                                jitter:(double)jitter
{
    return [[self alloc] initWithInitialTime:time0 maxTime:maxTime growFactor:growFactor jitter:jitter];
}

+ (instancetype)exponentialTimerWithInitialTime:(NSTimeInterval)initialTime
                                        maxTime:(NSTimeInterval)maxTime
{
    return [self exponentialTimerWithInitialTime:initialTime maxTime:maxTime jitter:kDefaultGrow];
}

+ (instancetype)exponentialTimerWithInitialTime:(NSTimeInterval)initialTime
                                        maxTime:(NSTimeInterval)maxTime
                                         jitter:(double)jitter
{
    return [[self alloc] initWithInitialTime:initialTime
                                     maxTime:maxTime
                                  growFactor:kDefaultGrow
                                      jitter:jitter];
}

- (instancetype)initWithInitialTime:(NSTimeInterval)initialTime
                            maxTime:(NSTimeInterval)maxTime
                         growFactor:(double)growFactor
                             jitter:(double)jitter
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _initialTime = initialTime;
    _currTime = initialTime;
    _maxTime = maxTime;
    _growFactor = growFactor;
    _jitter = jitter;
  
    return self;
}

- (NSTimeInterval)calculateNext
{
    NSTimeInterval t = self.currTime * self.growFactor;
    
    if (t > self.maxTime) {
        t = self.maxTime;
    }
    
    if (self.jitter < 0.0001) {
        self.currTime = t;
    }
    else {
        const double sigma = self.jitter * t;
        self.currTime = [[self class] normalWithMu:t sigma:sigma];
    }
    
    if (self.currTime > self.maxTime) {
        self.currTime = self.maxTime;
    }
    
    return self.currTime;
}

- (NSTimeInterval)timeIntervalAndCalculateNext
{
    const NSTimeInterval ret = self.currTime;
    [self calculateNext];
    return ret;
}

- (NSTimeInterval)timeInterval
{
    return self.currTime;
}

#define EXPT_MODULO ((u_int32_t)RAND_MAX)
#define EXPT_MODULO_F64 ((double)(EXPT_MODULO))
#define exptRandom() (arc4random_uniform(EXPT_MODULO + 1))

+ (NSTimeInterval)normalWithMu:(double)mu sigma:(double)sigma
{
    /**
     * Uses Kinderman and Monahan method. Reference: Kinderman,
     * A.J. and Monahan, J.F., "Computer generation of random
     * variables using the ratio of uniform deviates", ACM Trans
     * Math Software, 3, (1977), pp257-260.
    */
    for (unsigned i = 0; i < 20; ++i) // Try 20 times
    {
        const double a = ((double)exptRandom()) / EXPT_MODULO_F64;
        const double b = 1.0 - (((double)exptRandom()) / EXPT_MODULO_F64);
        // const static float NV_MAGICCONST = 1.7155277699214135; //4 * exp(-0.5)/sqrt(2.0);
        const double c = 1.7155277699214135 * (a - 0.5) / b;
        const double d = c * c / 4.0;
        
        if (d <= -1.0*log(b)) {
            return mu + c * sigma;
        }
    }
    
    return mu + 2.0 * sigma * (((double)exptRandom()) / EXPT_MODULO_F64);
}

- (void)reset
{
    self.currTime = self.initialTime;
}

@end
