@import Foundation;

#import "SPTDataLoaderRequestResponseHandler.h"

@class SPTDataLoaderResponse;

@interface SPTDataLoaderRequestResponseHandlerMock : NSObject <SPTDataLoaderRequestResponseHandler>

@property (nonatomic, assign, readonly) NSUInteger numberOfFailedResponseCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfCancelledRequestCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfReceivedDataRequestCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfSuccessfulDataResponseCalls;
@property (nonatomic, assign, readonly) NSUInteger numberOfReceivedInitialResponseCalls;
@property (nonatomic, strong, readonly) SPTDataLoaderResponse *lastReceivedResponse;

@end
