@import Foundation;

@class NSURLSessionDataTaskMock;

@interface NSURLSessionMock : NSURLSession

@property (nonatomic, strong) NSURLSessionDataTaskMock *lastDataTask;

@end
