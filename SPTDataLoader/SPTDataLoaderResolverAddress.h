#import <Foundation/Foundation.h>

/**
 * An object for tracking a resolver addresses reachability
 */
@interface SPTDataLoaderResolverAddress : NSObject

/**
 * The IP address
 */
@property (nonatomic, strong) NSString *address;
/**
 * Whether the IP address should currently be considered reachable
 */
@property (nonatomic, assign, readonly, getter = isReachable) BOOL reachable;

/**
 * Class constructor
 * @param address The IP address to represent
 */
+ (instancetype)dataLoaderResolverAddressWithAddress:(NSString *)address;

/**
 * Call when this address has failed to be contacted
 */
- (void)failedToReach;

@end
