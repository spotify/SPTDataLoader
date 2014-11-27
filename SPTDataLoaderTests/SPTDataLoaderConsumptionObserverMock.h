#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoaderConsumptionObserver.h>

@interface SPTDataLoaderConsumptionObserverMock : NSObject <SPTDataLoaderConsumptionObserver>

@property (nonatomic, assign) NSInteger numberOfCallsToEndedRequest;

@end
