#import <Foundation/Foundation.h>

@interface NSURLSessionMock : NSURLSession

@property (nonatomic, strong) NSURLSessionDataTask *lastDataTask;

@end
