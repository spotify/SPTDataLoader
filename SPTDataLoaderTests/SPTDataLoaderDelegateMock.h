#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoader.h>

@interface SPTDataLoaderDelegateMock : NSObject <SPTDataLoaderDelegate>

@property (nonatomic, assign) BOOL supportChunks;

@end
