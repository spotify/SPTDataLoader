#import <Foundation/Foundation.h>

@interface NSURLSessionDataTaskMock : NSURLSessionDataTask

@property (nonatomic, assign) NSUInteger numberOfCallsToResume;
@property (nonatomic, assign) NSUInteger numberOfCallsToCancel;

@end
