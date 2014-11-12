
#import <Foundation/Foundation.h>

FOUNDATION_EXPORT const double kDefaultJitter;

/**
 * Exponential timer with jitter for proper backoff handling in data transmissions
 */
@interface SPTExpTime : NSObject

/**
 * Create timer with initial time and max limit
 * @param time0 initial time to start counting delay from
 * @param manTime Upper limit which shouldnt be exceeded when calculatin new delay value
 */
+ (instancetype)expTimeWithInitialTime:(NSTimeInterval)time0 maxTime:(NSTimeInterval)maxTime;

/**
 * Create timer with initial time and max limit and user defined jitter
 * Default jitter gives vary good results. If you stil want to use your own jitter please do verification of delay values
 * you get from the timer once before puttin core into production.
 * @param time0 initial time to start counting delay from
 * @param manTime Upper limit which shouldnt be exceeded when calculatin new delay value
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
