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
#import <SPTDataLoader/SPTDataLoaderRequest.h>

#import "SPTDataLoaderRequest+Private.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const SPTDataLoaderRequestErrorDomain = @"com.spotify.dataloader.request";

static NSString * NSStringFromSPTDataLoaderRequestMethod(SPTDataLoaderRequestMethod requestMethod);

@interface SPTDataLoaderRequest ()

@property (nonatomic, assign, readwrite) int64_t uniqueIdentifier;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *mutableHeaders;
@property (nonatomic, assign) BOOL retriedAuthorisation;
@property (nonatomic, weak) id<SPTDataLoaderCancellationToken> cancellationToken;

@end

@implementation SPTDataLoaderRequest

#pragma mark SPTDataLoaderRequest

+ (instancetype)requestWithURL:(NSURL *)URL sourceIdentifier:(nullable NSString *)sourceIdentifier
{
    static int64_t uniqueIdentifierBarrier = 0;
    @synchronized(self.class) {
        return [[self alloc] initWithURL:URL
                        sourceIdentifier:sourceIdentifier
                        uniqueIdentifier:uniqueIdentifierBarrier++];
    }
}

- (instancetype)initWithURL:(NSURL *)URL
           sourceIdentifier:(nullable NSString *)sourceIdentifier
           uniqueIdentifier:(int64_t)uniqueIdentifier
{
    self = [super init];
    if (self) {
        _URL = URL;
        _sourceIdentifier = sourceIdentifier;
        _uniqueIdentifier = uniqueIdentifier;

        _mutableHeaders = [NSMutableDictionary new];
        _method = SPTDataLoaderRequestMethodGet;
    }

    return self;
}

- (NSDictionary *)headers
{
    @synchronized(self.mutableHeaders) {
        return [self.mutableHeaders copy];
    }
}

- (void)addValue:(NSString *)value forHeader:(NSString *)header
{
    if (!header) {
        return;
    }
    
    @synchronized(self.mutableHeaders) {
        if (!value && header) {
            [self.mutableHeaders removeObjectForKey:header];
            return;
        }
        
        self.mutableHeaders[header] = value;
    }
}

- (void)removeHeader:(NSString *)header
{
    @synchronized(self.mutableHeaders) {
        [self.mutableHeaders removeObjectForKey:header];
    }
}

#pragma mark Private

- (NSURLRequest *)urlRequest
{
    NSString * const SPTDataLoaderRequestContentLengthHeader = @"Content-Length";
    NSString * const SPTDataLoaderRequestAcceptLanguageHeader = @"Accept-Language";
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:self.URL];
    
    if (!self.headers[SPTDataLoaderRequestAcceptLanguageHeader]) {
        [urlRequest addValue:[self.class languageHeaderValue]
          forHTTPHeaderField:SPTDataLoaderRequestAcceptLanguageHeader];
    }

    if (self.bodyStream != nil) {
        urlRequest.HTTPBodyStream = self.bodyStream;
    } else if (self.body) {
        [urlRequest addValue:@(self.body.length).stringValue forHTTPHeaderField:SPTDataLoaderRequestContentLengthHeader];
        urlRequest.HTTPBody = self.body;
    }
    
    NSDictionary *headers = self.headers;
    for (NSString *key in headers) {
        NSString *value = headers[key];
        [urlRequest addValue:value forHTTPHeaderField:key];
    }
    
    urlRequest.cachePolicy = self.cachePolicy;
    urlRequest.HTTPMethod = NSStringFromSPTDataLoaderRequestMethod(self.method);
    
    return urlRequest;
}

+ (NSString *)languageHeaderValue
{
    static NSString * languageHeaderValue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        languageHeaderValue = [self generateLanguageHeaderValue];
    });
    return languageHeaderValue;
}

+ (NSString *)generateLanguageHeaderValue
{
    const NSInteger SPTDataLoaderRequestMaximumLanguages = 2;
    NSString * const SPTDataLoaderRequestEnglishLanguageValue = @"en";
    NSString * const SPTDataLoaderRequestLanguageHeaderValuesJoiner = @", ";

    NSString *(^constructLanguageHeaderValue)(NSString *, double) = ^NSString *(NSString *language, double languageImportance) {
        NSString * const SPTDataLoaderRequestLanguageFormatString = @"%@;q=%.2f";
        return [NSString stringWithFormat:SPTDataLoaderRequestLanguageFormatString, language, languageImportance];
    };

    NSArray *languages = [NSBundle mainBundle].preferredLocalizations;
    if (languages.count > SPTDataLoaderRequestMaximumLanguages) {
        languages = [languages subarrayWithRange:NSMakeRange(0, SPTDataLoaderRequestMaximumLanguages)];
    }
    double languageImportanceCounter = 1.0;
    NSMutableArray *languageHeaderValues = [NSMutableArray arrayWithCapacity:languages.count];
    BOOL containsEnglish = NO;
    for (NSString *language in languages) {
        if (!containsEnglish) {
            NSString * const SPTDataLoaderRequestLanguageLocaleSeparator = @"-";
            NSString *languageValue = [language componentsSeparatedByString:SPTDataLoaderRequestLanguageLocaleSeparator].firstObject;
            if ([languageValue isEqualToString:SPTDataLoaderRequestEnglishLanguageValue]) {
                containsEnglish = YES;
            }
        }

        if (languageImportanceCounter == 1.0) {
            [languageHeaderValues addObject:language];
        } else {
            [languageHeaderValues addObject:constructLanguageHeaderValue(language, languageImportanceCounter)];
        }
        languageImportanceCounter -= (1.0 / languages.count);
    }
    if (!containsEnglish) {
        [languageHeaderValues addObject:constructLanguageHeaderValue(SPTDataLoaderRequestEnglishLanguageValue, 0.01)];
    }
    return [languageHeaderValues componentsJoinedByString:SPTDataLoaderRequestLanguageHeaderValuesJoiner];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p URL = \"%@\">", self.class, (void *)self, self.URL];
}

#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    __typeof(self) copy = [[self.class alloc] initWithURL:self.URL
                                         sourceIdentifier:self.sourceIdentifier
                                         uniqueIdentifier:self.uniqueIdentifier];
    copy.maximumRetryCount = self.maximumRetryCount;
    copy.body = [self.body copy];
    @synchronized(self.mutableHeaders) {
        copy.mutableHeaders = [self.mutableHeaders mutableCopy];
    }
    copy.chunks = self.chunks;
    copy.cachePolicy = self.cachePolicy;
    copy.skipNSURLCache = self.skipNSURLCache;
    copy.method = self.method;
    copy.backgroundPolicy = self.backgroundPolicy;
    copy.userInfo = self.userInfo;
    copy.timeout = self.timeout;
    copy.cancellationToken = self.cancellationToken;
    copy.bodyStream = self.bodyStream;
    return copy;
}

@end

static NSString * const SPTDataLoaderRequestDeleteMethodString = @"DELETE";
static NSString * const SPTDataLoaderRequestGetMethodString = @"GET";
static NSString * const SPTDataLoaderRequestPatchMethodString = @"PATCH";
static NSString * const SPTDataLoaderRequestPostMethodString = @"POST";
static NSString * const SPTDataLoaderRequestPutMethodString = @"PUT";
static NSString * const SPTDataLoaderRequestHeadMethodString = @"HEAD";

static NSString * NSStringFromSPTDataLoaderRequestMethod(SPTDataLoaderRequestMethod requestMethod)
{
    switch (requestMethod) {
        case SPTDataLoaderRequestMethodDelete: return SPTDataLoaderRequestDeleteMethodString;
        case SPTDataLoaderRequestMethodGet: return SPTDataLoaderRequestGetMethodString;
        case SPTDataLoaderRequestMethodPatch: return SPTDataLoaderRequestPatchMethodString;
        case SPTDataLoaderRequestMethodPost: return SPTDataLoaderRequestPostMethodString;
        case SPTDataLoaderRequestMethodPut: return SPTDataLoaderRequestPutMethodString;
        case SPTDataLoaderRequestMethodHead: return SPTDataLoaderRequestHeadMethodString;
    }
}

NS_ASSUME_NONNULL_END
