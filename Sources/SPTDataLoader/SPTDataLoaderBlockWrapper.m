/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <SPTDataLoader/SPTDataLoader.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const BlockRequestIdentifierKey = @"BlockRequestIdentifierKey";

@interface SPTDataLoaderBlockWrapper () <SPTDataLoaderDelegate>

@property (nonatomic, strong) SPTDataLoader *dataLoader;

@end

@implementation SPTDataLoaderBlockWrapper

- (instancetype)initWithDataLoader:(SPTDataLoader *)dataLoader
{
    self = [super init];
    if (self) {
        _dataLoader = dataLoader;
        dataLoader.delegate = self;
    }
    return self;
}

- (nullable id<SPTDataLoaderCancellationToken>)performRequest:(SPTDataLoaderRequest *)request completion:(SPTDataLoaderBlockCompletion)completion
{
    NSMutableDictionary *mutableUserInfo = [request.userInfo mutableCopy] ?: [NSMutableDictionary new];
    mutableUserInfo[BlockRequestIdentifierKey] = [completion copy];
    request.userInfo = mutableUserInfo;

    return [self.dataLoader performRequest:request];
}

- (void)dataLoader:(nonnull SPTDataLoader *)dataLoader didReceiveErrorResponse:(nonnull SPTDataLoaderResponse *)response
{
    SPTDataLoaderBlockCompletion completion = response.request.userInfo[BlockRequestIdentifierKey];
    if (completion != nil) {
        completion(response, response.error);
    }
}

- (void)dataLoader:(nonnull SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(nonnull SPTDataLoaderResponse *)response
{
    SPTDataLoaderBlockCompletion completion = response.request.userInfo[BlockRequestIdentifierKey];
    if (completion != nil) {
        completion(response, nil);
    }
}

@end

NS_ASSUME_NONNULL_END
