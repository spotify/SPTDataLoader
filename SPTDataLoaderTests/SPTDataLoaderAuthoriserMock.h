@import Foundation;

#import "SPTDataLoaderAuthoriser.h"

@interface SPTDataLoaderAuthoriserMock : NSObject <SPTDataLoaderAuthoriser>

@property (nonatomic, assign, readonly) NSUInteger numberOfCallsToAuthoriseRequest;
@property (nonatomic, assign, readwrite, getter = isEnabled) BOOL enabled;

@end
