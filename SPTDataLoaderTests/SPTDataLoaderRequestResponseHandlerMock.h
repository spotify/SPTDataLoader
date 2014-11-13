#import <Foundation/Foundation.h>

#import "SPTDataLoaderRequestResponseHandler.h"

@interface SPTDataLoaderRequestResponseHandlerMock : NSObject <SPTDataLoaderRequestResponseHandler>

@property (nonatomic, assign, readonly) NSUInteger numberOfFailedResponseCalls;

@end
