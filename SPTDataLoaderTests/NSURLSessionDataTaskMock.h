@import Foundation;

@interface NSURLSessionDataTaskMock : NSURLSessionDataTask

@property (nonatomic, assign) NSUInteger numberOfCallsToResume;
@property (nonatomic, assign) NSUInteger numberOfCallsToCancel;

#pragma mark NSURLSessionTask

@property (atomic, nullable, readonly, copy) NSURLRequest *currentRequest;
@property (atomic, nullable, readonly, copy) NSURLResponse *response;

@property (atomic, readonly) int64_t countOfBytesSent;
@property (atomic, readonly) int64_t countOfBytesReceived;

@end
