#import <Foundation/Foundation.h>

#import "SPTDataLoaderCancellationTokenFactory.h"

@interface SPTDataLoaderCancellationTokenFactoryMock : NSObject <SPTDataLoaderCancellationTokenFactory>

@property (nonatomic, strong, readwrite) id<SPTDataLoaderCancellationTokenDelegate> overridingDelegate;

@end
