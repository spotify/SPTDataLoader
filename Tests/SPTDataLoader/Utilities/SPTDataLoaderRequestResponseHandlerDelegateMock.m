/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "SPTDataLoaderRequestResponseHandlerDelegateMock.h"

@implementation SPTDataLoaderRequestResponseHandlerDelegateMock

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                performRequest:(SPTDataLoaderRequest *)request
{
    self.lastRequestPerformed = request;
}

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
             authorisedRequest:(SPTDataLoaderRequest *)request
{
    self.lastRequestAuthorised = request;
}

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
      failedToAuthoriseRequest:(SPTDataLoaderRequest *)request
                         error:(NSError *)error
{
    self.lastRequestFailed = request;
}

- (void)requestResponseHandler:(id<SPTDataLoaderRequestResponseHandler>)requestResponseHandler
                 cancelRequest:(SPTDataLoaderRequest *)request
{
    self.lastRequestCancelled = request;
}

@end
