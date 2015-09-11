#import <Foundation/Foundation.h>

#import "SPTDataLoaderConsumptionObserver.h"

@interface SPTDataLoaderConsumptionObserverMock : NSObject <SPTDataLoaderConsumptionObserver>

@property (nonatomic, assign) NSInteger numberOfCallsToEndedRequest;

@end
