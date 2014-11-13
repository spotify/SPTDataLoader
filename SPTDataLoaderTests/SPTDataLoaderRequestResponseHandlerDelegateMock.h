#import <Foundation/Foundation.h>

#import "SPTDataLoaderRequestResponseHandler.h"

@interface SPTDataLoaderRequestResponseHandlerDelegateMock : NSObject <SPTDataLoaderRequestResponseHandlerDelegate>

@property (nonatomic, strong) SPTDataLoaderRequest *lastRequestPerformed;

@end
