#import <Foundation/Foundation.h>

#import <SPTDataLoader/SPTDataLoader.h>

@interface SPTDataLoaderAuthoriserOAuth : NSObject <SPTDataLoaderAuthoriser>

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                 dataLoaderFactory:(SPTDataLoaderFactory *)dataLoaderFactory NS_DESIGNATED_INITIALIZER;

@end
