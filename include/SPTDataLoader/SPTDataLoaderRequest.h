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
 * The number of times to retry this request in the event of a failure
 * @discussion The default is 0
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
 * The cache policy to use for this request
 */
@property (nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
/**
 * The method used to send the request
 * @discussion The default request method is SPTDataLoaderRequestMethodGet
 */
@property (nonatomic, assign) SPTDataLoaderRequestMethod method;
/**
 * Any user information tied to this request
 */
@property (nonatomic, strong) NSDictionary *userInfo;

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
