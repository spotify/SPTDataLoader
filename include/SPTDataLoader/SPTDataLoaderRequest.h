#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SPTDataLoaderRequestMethod) {
    SPTDataLoaderRequestMethodGet,
    SPTDataLoaderRequestMethodPost,
    SPTDataLoaderRequestMethodPut,
    SPTDataLoaderRequestMethodDelete
};

extern NSString * const SPTDataLoaderRequestHostHeader;

/**
 * A representing of the request to make to the backend
 */
@interface SPTDataLoaderRequest : NSObject <NSCopying>

/**
 * The URL to request
 */
@property (nonatomic, strong) NSURL *URL;
/**
 * The number of times to retry this request
 */
@property (nonatomic, assign) NSUInteger retryCount;
/**
 * The body of the request
 */
@property (nonatomic, strong) NSData *body;
/**
 * The headers represented by a dictionary
 */
@property (nonatomic, strong, readonly) NSDictionary *headers;
/**
 * Whether the result of the request should be delivered in chunks
 */
@property (nonatomic, assign) BOOL chunks;
/**
 * The cache policy to use for this request
 */
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
/**
 * The method used to send the request
 */
@property (nonatomic, assign) SPTDataLoaderRequestMethod method;

/**
 * Class constructor
 * @param URL The URL to query
 */
+ (instancetype)requestWithURL:(NSURL *)URL;

/**
 * Adds a header value
 * @param value The value of the header field
 * @param header The header field to add the value to
 */
- (void)addValue:(NSString *)value forHeader:(NSString *)header;
/**
 * Removes a header value
 * @param header The header field to remove
 */
- (void)removeHeader:(NSString *)header;

@end
