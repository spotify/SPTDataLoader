/*
 Copyright (c) 2015-2019 Spotify AB.

 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */
#import "NSURLAuthenticationChallengeMock.h"

@interface NSURLProtectionSpaceMock : NSURLProtectionSpace {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-interface-ivars"
    SecTrustRef _mockServerTrust;
#pragma clang diagnostic pop
}

@property (nonatomic, copy) NSString *mockHost;

- (SecTrustRef)mockServerTrust;

- (void)setMockServerTrust:(SecTrustRef)trust;

@end

@implementation NSURLAuthenticationChallengeMock

+ (instancetype)mockAuthenticationChallengeWithHost:(NSString *)host
                               authenticationMethod:(NSString *)authenticationMethod
                                        serverTrust:(SecTrustRef)serverTrust
{
    NSURLProtectionSpaceMock *mockProtectionSpace = [[NSURLProtectionSpaceMock alloc] initWithHost:host ?: @"host"
                                                                                              port:443
                                                                                          protocol:NSURLProtectionSpaceHTTPS
                                                                                             realm:nil
                                                                              authenticationMethod:authenticationMethod];
    mockProtectionSpace.mockHost = host;
    mockProtectionSpace.mockServerTrust = serverTrust;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    NSURLAuthenticationChallengeMock *mock = [[NSURLAuthenticationChallengeMock alloc] initWithProtectionSpace:mockProtectionSpace
                                                                                            proposedCredential:nil
                                                                                          previousFailureCount:0
                                                                                               failureResponse:nil
                                                                                                         error:NULL
                                                                                                        sender:nil];
#pragma clang diagnostic pop
    return mock;
}

@end

@implementation NSURLProtectionSpaceMock

#pragma mark Overrides

- (NSString *)host
{
    return self.mockHost;
}

- (SecTrustRef)serverTrust
{
    return self.mockServerTrust;
}

- (void)dealloc
{
    if (_mockServerTrust) {
        CFRelease(_mockServerTrust);
        _mockServerTrust = NULL;
    }
}

#pragma mark Mock

- (SecTrustRef)mockServerTrust
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    return _mockServerTrust;
#pragma clang diagnostic pop
}

- (void)setMockServerTrust:(SecTrustRef)trust
{
    if (trust) {
        CFRetain(trust);
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdirect-ivar-access"
    
    if (_mockServerTrust) {
        CFRelease(_mockServerTrust);
    }
    
    _mockServerTrust = trust;
    
#pragma clang diagnostic pop
}

@end
