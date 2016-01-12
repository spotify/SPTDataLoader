#import <Foundation/Foundation.h>

@interface NSURLSessionDataTaskMock : NSURLSessionDataTask

@property (nonatomic, assign) NSUInteger numberOfCallsToResume;
@property (nonatomic, assign) NSUInteger numberOfCallsToCancel;

#pragma mark NSURLSessionTask

@property (copy) NSURLRequest *currentRequest;
@property (copy) NSURLResponse *response;

@property int64_t countOfBytesSent;
@property int64_t countOfBytesReceived;

@end
