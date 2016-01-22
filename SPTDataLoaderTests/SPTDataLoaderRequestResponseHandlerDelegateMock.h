@import Foundation;

#import "SPTDataLoaderRequestResponseHandler.h"

typedef id<SPTCancellationToken> (^SPTCancellationTokenCreator)();

@interface SPTDataLoaderRequestResponseHandlerDelegateMock : NSObject <SPTDataLoaderRequestResponseHandlerDelegate>

@property (nonatomic, strong) SPTDataLoaderRequest *lastRequestPerformed;
@property (nonatomic, strong) SPTDataLoaderRequest *lastRequestAuthorised;
@property (nonatomic, strong) SPTDataLoaderRequest *lastRequestFailed;
@property (nonatomic, copy) SPTCancellationTokenCreator tokenCreator;

@end
