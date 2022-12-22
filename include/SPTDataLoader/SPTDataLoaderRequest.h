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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SPTDataLoaderRequestMethod) {
    SPTDataLoaderRequestMethodGet,
    SPTDataLoaderRequestMethodPatch,
    SPTDataLoaderRequestMethodPost,
    SPTDataLoaderRequestMethodPut,
    SPTDataLoaderRequestMethodDelete,
    SPTDataLoaderRequestMethodHead
};

extern NSString * const SPTDataLoaderRequestErrorDomain;

typedef NS_ERROR_ENUM(SPTDataLoaderRequestErrorDomain, SPTDataLoaderRequestErrorCode) {
    SPTDataLoaderRequestErrorCodeTimeout,
    SPTDataLoaderRequestErrorChunkedRequestWithoutChunkedDelegate
};

/**
 How the request should be handled when the application enters the background

 - SPTDataLoaderRequestBackgroundPolicyDefault: Allow the system to fail in-flight requests in the background
 - SPTDataLoaderRequestBackgroundPolicyOnDemand: Hint to the system to upgrade this request to a background task
 - SPTDataLoaderRequestBackgroundPolicyAlways: Use a background task but do not return response headers or status code
 */
typedef NS_ENUM(NSInteger, SPTDataLoaderRequestBackgroundPolicy) {
    SPTDataLoaderRequestBackgroundPolicyDefault,
    SPTDataLoaderRequestBackgroundPolicyOnDemand,
    SPTDataLoaderRequestBackgroundPolicyAlways
};

/**
 A representing of the request to make to the backend
 */
@interface SPTDataLoaderRequest : NSObject <NSCopying>

/**
 The URL to request
 */
@property (nonatomic, strong) NSURL *URL;
/**
 A Boolean value that indicates whether the session should wait for connectivity to become
 available, or fail immediately.
 @discussion See documentation for NSURLSession.waitsForConnectivity for detailed semantics.
 This flag is ignored on OS versions earlier than iOS 11, macOS 10.13, tvOS 11, and watchOS 4.
 */
@property (nonatomic, assign) BOOL waitsForConnectivity;
/**
 The number of times to retry this request in the event of a failure
 @discussion The default is 0
 */
@property (nonatomic, assign) NSUInteger maximumRetryCount;
/**
 The body of the request
 */
@property (nonatomic, strong, nullable) NSData *body;
/**
 The headers represented by a dictionary
 */
@property (nonatomic, strong, readonly) NSDictionary<NSString *, NSString *> *headers;
/**
 Whether the result of the request should be delivered in chunks
 @discussion This will only generate chunks if the data loader delegate is set up to receive them
 */
@property (nonatomic, assign) BOOL chunks;
/**
 The cache policy to use for this request
 */
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
/**
 Whether or not this request should skip storage in the NSURLCache when completed
 */
@property (nonatomic, assign) BOOL skipNSURLCache;
/**
 The method used to send the request
 @discussion The default request method is SPTDataLoaderRequestMethodGet
 */
@property (nonatomic, assign) SPTDataLoaderRequestMethod method;
/**
 Whether or not this request should use a background download task.
 */
@property (nonatomic, assign) SPTDataLoaderRequestBackgroundPolicy backgroundPolicy;
/**
 Any user information tied to this request
 */
@property (nonatomic, strong) NSDictionary *userInfo;
/**
 An identifier for uniquely identifying the request
 */
@property (nonatomic, assign, readonly) int64_t uniqueIdentifier;
/**
 The absolute timeout for the request to respect
 @discussion The default is 0.0, which is the equivalent of no timeout
 */
@property (nonatomic, assign) NSTimeInterval timeout;
/**
 An input stream that can be used to stream a body
 */
@property (nonatomic, strong, readwrite) NSInputStream *bodyStream;
/**
 An identifier for the request source. May be nil.

 @discussion This is used for logging purposes to locate where data is downloaded from.
 */
@property (nonatomic, copy, nullable) NSString *sourceIdentifier;
/**
 A Boolean value that indicates whether the redirection should happen for a request.
 @discussion default is NO.
 */
@property (nonatomic, assign) BOOL shouldStopRedirection;

/**
 Class constructor
 @param URL The URL to query
 @param sourceIdentifier An identifier for the request source. May be nil.
 */
+ (instancetype)requestWithURL:(NSURL *)URL sourceIdentifier:(nullable NSString *)sourceIdentifier;

/**
 The value to be added to the Accept-Language header by default
 */
+ (NSString *)languageHeaderValue;

/**
 Adds a header value
 @param value The value of the header field
 @param header The header field to add the value to
 */
- (void)addValue:(NSString *)value forHeader:(NSString *)header;
/**
 Removes a header value
 @param header The header field to remove
 */
- (void)removeHeader:(NSString *)header;

@end

NS_ASSUME_NONNULL_END
