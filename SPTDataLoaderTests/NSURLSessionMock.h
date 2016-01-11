#import <Foundation/Foundation.h>

@class NSURLSessionDataTaskMock;

@interface NSURLSessionMock : NSURLSession

@property (nonatomic, strong) NSURLSessionDataTaskMock *lastDataTask;

@end
