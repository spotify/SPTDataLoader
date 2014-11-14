#import <Foundation/Foundation.h>

@interface NSURLSessionTaskMock : NSURLSessionTask

@property (nonatomic, assign) NSUInteger numberOfCallsToResume;
@property (nonatomic, assign) NSUInteger numberOfCallsToCancel;

@end
