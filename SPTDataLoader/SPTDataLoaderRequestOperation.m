#import "SPTDataLoaderRequestOperation.h"

#import "SPTCancellationToken.h"

@interface SPTDataLoaderRequestOperation ()

@property (nonatomic, strong) SPTDataLoaderRequest *request;
@property (nonatomic, strong) NSURLSessionTask *task;

@end

@implementation SPTDataLoaderRequestOperation

#pragma mark SPTDataLoaderRequestOperation

+ (instancetype)dataLoaderRequestOperationWithRequest:(SPTDataLoaderRequest *)request
                                                 task:(NSURLSessionTask *)task
                                    cancellationToken:(id<SPTCancellationToken>)cancellationToken
{
    return [[self alloc] initWithRequest:request task:task cancellationToken:cancellationToken];
}

- (instancetype)initWithRequest:(SPTDataLoaderRequest *)request
                           task:(NSURLSessionTask *)task
              cancellationToken:(id<SPTCancellationToken>)cancellationToken
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _request = request;
    _task = task;
    _cancellationToken = cancellationToken;
    
    return self;
}

@end
