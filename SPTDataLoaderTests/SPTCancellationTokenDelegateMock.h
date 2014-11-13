#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTCancellationToken.h>

@interface SPTCancellationTokenDelegateMock : NSObject <SPTCancellationTokenDelegate>

@property (nonatomic, assign) NSUInteger numberOfCallsToCancellationTokenDidCancel;

@end
