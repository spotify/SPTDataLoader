/*
 Copyright 2015-2022 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "SPTDataLoaderAuthoriserMock.h"

@interface SPTDataLoaderAuthoriserMock ()

@property (nonatomic, assign, readwrite) NSUInteger numberOfCallsToAuthoriseRequest;

@end

@implementation SPTDataLoaderAuthoriserMock

@synthesize identifier = _identifier;
@synthesize delegate = _delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _enabled = YES;
    }
    return self;
}

- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request
{
    return self.enabled;
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
    self.numberOfCallsToAuthoriseRequest++;
    [self.delegate dataLoaderAuthoriser:self authorisedRequest:request];
}

- (void)requestFailedAuthorisation:(SPTDataLoaderRequest *)request response:(SPTDataLoaderResponse *)response
{
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self.class new];
}

- (void)refresh
{
    
}

@end
