#import <Foundation/Foundation.h>

/// http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
typedef NS_ENUM(NSInteger, SPTDataLoaderResponseHTTPStatusCode) {
    // Informational
    SPTDataLoaderResponseHTTPStatusCodeContinue = 100,
    SPTDataLoaderResponseHTTPStatusCodeSwitchProtocols = 101,
    // Successful
    SPTDataLoaderResponseHTTPStatusCodeOK = 200,
    SPTDataLoaderResponseHTTPStatusCodeCreated = 201,
    SPTDataLoaderResponseHTTPStatusCodeAccepted = 202,
    SPTDataLoaderResponseHTTPStatusCodeNonAuthoritiveInformation = 203,
    SPTDataLoaderResponseHTTPStatusCodeNoContent = 204,
    SPTDataLoaderResponseHTTPStatusCodeResetContent = 205,
    SPTDataLoaderResponseHTTPStatusCodePartialContent = 206,
    // Redirection
    SPTDataLoaderResponseHTTPStatusCodeMovedMultipleChoices = 300,
    SPTDataLoaderResponseHTTPStatusCodeMovedPermanently = 301,
    SPTDataLoaderResponseHTTPStatusCodeFound = 302,
    SPTDataLoaderResponseHTTPStatusCodeSeeOther = 303,
    SPTDataLoaderResponseHTTPStatusCodeNotModified = 304,
    SPTDataLoaderResponseHTTPStatusCodeUseProxy = 305,
    SPTDataLoaderResponseHTTPStatusCodeUnused = 306,
    SPTDataLoaderResponseHTTPStatusCodeTemporaryRedirect = 307,
    // Client Error
    SPTDataLoaderResponseHTTPStatusCodeBadRequest = 400,
    SPTDataLoaderResponseHTTPStatusCodeUnauthorised = 401,
    SPTDataLoaderResponseHTTPStatusCodePaymentRequired = 402,
    SPTDataLoaderResponseHTTPStatusCodeForbidden = 403,
    SPTDataLoaderResponseHTTPStatusCodeNotFound = 404,
    SPTDataLoaderResponseHTTPStatusCodeMethodNotAllowed = 405,
    SPTDataLoaderResponseHTTPStatusCodeNotAcceptable = 406,
    SPTDataLoaderResponseHTTPStatusCodeProxyAuthenticationRequired = 407,
    SPTDataLoaderResponseHTTPStatusCodeRequestTimeout = 408,
    SPTDataLoaderResponseHTTPStatusCodeConflict = 409,
    SPTDataLoaderResponseHTTPStatusCodeGone = 410,
    SPTDataLoaderResponseHTTPStatusCodeLengthRequired = 411,
    SPTDataLoaderResponseHTTPStatusCodePreconditionFailed = 412,
    SPTDataLoaderResponseHTTPStatusCodeRequestEntityTooLarge = 413,
    SPTDataLoaderResponseHTTPStatusCodeRequestURITooLong = 414,
    SPTDataLoaderResponseHTTPStatusCodeUnsupportedMediaTypes = 415,
    SPTDataLoaderResponseHTTPStatusCodeRequestRangeUnsatisifiable = 416,
    SPTDataLoaderResponseHTTPStatusCodeExpectationFail = 417,
    // Server Error
    SPTDataLoaderResponseHTTPStatusCodeInternalServerError = 500,
    SPTDataLoaderResponseHTTPStatusCodeNotImplemented = 501,
    SPTDataLoaderResponseHTTPStatusCodeBadGateway = 502,
    SPTDataLoaderResponseHTTPStatusCodeServiceUnavailable = 503,
    SPTDataLoaderResponseHTTPStatusCodeGatewayTimeout = 504,
    SPTDataLoaderResponseHTTPStatusCodeHTTPVersionNotSupported = 505
};

@class SPTDataLoaderRequest;

extern NSString * const SPTDataLoaderResponseErrorDomain;

/**
 * An object representing the response from the backend
 */
@interface SPTDataLoaderResponse : NSObject

/**
 * The request object that generated the request
 */
@property (nonatomic, strong, readonly) SPTDataLoaderRequest *request;
/**
 * The error that the request generated
 */
@property (nonatomic, strong, readonly) NSError *error;
/**
 * The headers that the server returned with a request
 */
@property (nonatomic, strong, readonly) NSDictionary *headers;
/**
 * The date at which the request that generated the response can be retried
 */
@property (nonatomic, strong, readonly) NSDate *retryAfter;
/**
 * The body of data contained in the response
 */
@property (nonatomic, strong, readonly) NSData *body;

@end
