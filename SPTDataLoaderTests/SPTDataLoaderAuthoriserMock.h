#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoaderAuthoriser.h>

@interface SPTDataLoaderAuthoriserMock : NSObject <SPTDataLoaderAuthoriser>

@property (nonatomic, assign, readonly) NSUInteger numberOfCallsToAuthoriseRequest;

@end
