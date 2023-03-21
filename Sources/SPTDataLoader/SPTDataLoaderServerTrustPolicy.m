/*
 Copyright 2015-2023 Spotify AB

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

#import <SPTDataLoader/SPTDataLoaderServerTrustPolicy.h>

#import "SPTDataLoaderServerTrustPolicy+Private.h"

#import <Security/Security.h>

static BOOL SPTEvaluteTrust(SecTrustRef trust) {
    BOOL isValid = NO;
    SecTrustResultType result;

    if (@available(iOS 12, macOS 14, tvOS 12, watchOS 5, *)) {
        isValid = SecTrustEvaluateWithError(trust,  nil);
    } else {
        OSStatus status = SecTrustEvaluate(trust, &result);
        if (status == errSecSuccess) {
            isValid = (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
        }
    }

    return isValid;
}

static NSArray * SPTCertificatesForTrust(SecTrustRef trust) {
    CFIndex count = SecTrustGetCertificateCount(trust);
    NSMutableArray *certificates = [NSMutableArray arrayWithCapacity:(NSUInteger)count];

    for (CFIndex i = 0; i < count; i++) {
        SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trust, i);
        [certificates addObject:(__bridge_transfer NSData *)SecCertificateCopyData(certificate)];
    }

    return [NSArray arrayWithArray:certificates];
}

@interface SPTDataLoaderServerTrustPolicy ()

@property (nonatomic, strong) NSDictionary<NSString *, NSArray<NSData *> *> *trustedHostsAndCertificates;

@end

@implementation SPTDataLoaderServerTrustPolicy

#pragma mark SPTDataLoaderServerTrustPolicy

+ (instancetype)policyWithHostsAndCertificatePaths:(NSDictionary<NSString *, NSArray<NSString *> *> *)hostsAndCertificatePaths
{
    if (!hostsAndCertificatePaths) {
        return nil;
    }

    return [[self alloc] initWithHostsAndCertificatePaths:hostsAndCertificatePaths];
}

- (BOOL)validateChallenge:(NSURLAuthenticationChallenge *)challenge
{
    NSString *authenticationMethod = [challenge.protectionSpace authenticationMethod];
    if (![authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        return NO;
    }

    SecTrustRef trust = challenge.protectionSpace.serverTrust;
    if (!trust) {
        return NO;
    }

    NSString *host = challenge.protectionSpace.host;
    if (!host) {
        return NO;
    }

    return [self validateWithTrust:trust host:host];
}

#pragma mark Private

- (nullable NSArray<NSData *> *)certificatesForHost:(NSString *)host
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ like SELF", host];
    NSArray<NSString *> *allHosts = [self.trustedHostsAndCertificates allKeys];
    NSArray *hosts = [allHosts filteredArrayUsingPredicate:predicate];

    if ([hosts count] == 0) {
        return nil;
    }

    NSMutableArray<NSData *> *certificates = [NSMutableArray new];
    for (NSString *key in hosts) {
        NSArray<NSData *> *value = self.trustedHostsAndCertificates[key];
        [certificates addObjectsFromArray:value];
    }

    return [certificates copy];
}

- (BOOL)validateWithTrust:(SecTrustRef)trust host:(NSString *)host
{
    if (!host) {
        return NO;
    }

    NSMutableArray *policies = [NSMutableArray new];
    id policy = (__bridge_transfer id)SecPolicyCreateSSL(true, (__bridge CFStringRef)host);
    [policies addObject:policy];

    SecTrustSetPolicies(trust, (__bridge CFArrayRef)(policies));

    if (!SPTEvaluteTrust(trust)) {
        return NO;
    }

    NSArray<NSData *> *certificateData = [self certificatesForHost:host];

    if (!certificateData || [certificateData count] == 0) {
        return NO;
    }

    NSMutableArray *certificates = [NSMutableArray new];
    for (NSData *data  in certificateData) {
        id cert = (__bridge_transfer id)SecCertificateCreateWithData(NULL, (__bridge CFDataRef)data);
        [certificates addObject:cert];
    }
    SecTrustSetAnchorCertificates(trust, (__bridge CFArrayRef)certificates);

    if (!SPTEvaluteTrust(trust)) {
        return NO;
    }

    NSArray<NSData *> *trustCertificates = SPTCertificatesForTrust(trust);

    for (NSData *trustCertificate in [trustCertificates reverseObjectEnumerator]) {
        if ([certificateData containsObject:trustCertificate]) {
            return YES;
        }
    }

    return NO;
}

#pragma mark Lifecycle

- (instancetype)initWithHostsAndCertificatePaths:(NSDictionary<NSString *, NSArray<NSString *> *> *)hostsAndCertificatePaths
{
    self = [super init];
    if (self) {
        NSMutableDictionary<NSString *, NSArray<NSData *> *> *mutableDictionary = [NSMutableDictionary new];

        [hostsAndCertificatePaths enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<NSString *> * _Nonnull paths, BOOL * _Nonnull stop) {
            NSMutableArray<NSData *> *certificates = [NSMutableArray new];
            for (NSString *path in paths) {
                NSData *data = [NSData dataWithContentsOfFile:path];
                if (!data) {
                    continue;
                }
                [certificates addObject:data];
            }
            mutableDictionary[key] = [certificates copy];
        }];

        _trustedHostsAndCertificates = [mutableDictionary copy];
    }
    return self;
}

@end
