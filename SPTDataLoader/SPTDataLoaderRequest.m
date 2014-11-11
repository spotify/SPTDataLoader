#import "SPTDataLoaderRequest.h"

#import "SPTDataLoaderRequest+Private.h"

/// http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
typedef NS_ENUM(NSInteger, SPTDataLoaderRequestHTTPStatusCode) {
    // Informational
    SPTDataLoaderRequestHTTPStatusCodeContinue = 100,
    SPTDataLoaderRequestHTTPStatusCodeSwitchProtocols = 101,
    // Successful
    SPTDataLoaderRequestHTTPStatusCodeOK = 200,
    SPTDataLoaderRequestHTTPStatusCodeCreated = 201,
    SPTDataLoaderRequestHTTPStatusCodeAccepted = 202,
    SPTDataLoaderRequestHTTPStatusCodeNonAuthoritiveInformation = 203,
    SPTDataLoaderRequestHTTPStatusCodeNoContent = 204,
    SPTDataLoaderRequestHTTPStatusCodeResetContent = 205,
    SPTDataLoaderRequestHTTPStatusCodePartialContent = 206,
    // Redirection
    SPTDataLoaderRequestHTTPStatusCodeMovedMultipleChoices = 300,
    SPTDataLoaderRequestHTTPStatusCodeMovedPermanently = 301,
    SPTDataLoaderRequestHTTPStatusCodeFound = 302,
    SPTDataLoaderRequestHTTPStatusCodeSeeOther = 303,
    SPTDataLoaderRequestHTTPStatusCodeNotModified = 304,
    SPTDataLoaderRequestHTTPStatusCodeUseProxy = 305,
    SPTDataLoaderRequestHTTPStatusCodeUnused = 306,
    SPTDataLoaderRequestHTTPStatusCodeTemporaryRedirect = 307,
    // Client Error
    SPTDataLoaderRequestHTTPStatusCodeBadRequest = 400,
    SPTDataLoaderRequestHTTPStatusCodeUnauthorised = 401,
    SPTDataLoaderRequestHTTPStatusCodePaymentRequired = 402,
    SPTDataLoaderRequestHTTPStatusCodeForbidden = 403,
    SPTDataLoaderRequestHTTPStatusCodeNotFound = 404,
    SPTDataLoaderRequestHTTPStatusCodeMethodNotAllowed = 405,
    SPTDataLoaderRequestHTTPStatusCodeNotAcceptable = 406,
    SPTDataLoaderRequestHTTPStatusCodeProxyAuthenticationRequired = 407,
    SPTDataLoaderRequestHTTPStatusCodeRequestTimeout = 408,
    SPTDataLoaderRequestHTTPStatusCodeConflict = 409,
    SPTDataLoaderRequestHTTPStatusCodeGone = 410,
    SPTDataLoaderRequestHTTPStatusCodeLengthRequired = 411,
    SPTDataLoaderRequestHTTPStatusCodePreconditionFailed = 412,
    SPTDataLoaderRequestHTTPStatusCodeRequestEntityTooLarge = 413,
    SPTDataLoaderRequestHTTPStatusCodeRequestURITooLong = 414,
    SPTDataLoaderRequestHTTPStatusCodeUnsupportedMediaTypes = 415,
    SPTDataLoaderRequestHTTPStatusCodeRequestRangeUnsatisifiable = 416,
    SPTDataLoaderRequestHTTPStatusCodeExpectationFail = 417,
    // Server Error
    SPTDataLoaderRequestHTTPStatusCodeInternalServerError = 500,
    SPTDataLoaderRequestHTTPStatusCodeNotImplemented = 501,
    SPTDataLoaderRequestHTTPStatusCodeBadGateway = 502,
    SPTDataLoaderRequestHTTPStatusCodeServiceUnavailable = 503,
    SPTDataLoaderRequestHTTPStatusCodeGatewayTimeout = 504,
    SPTDataLoaderRequestHTTPStatusCodeHTTPVersionNotSupported = 505
};

@implementation SPTDataLoaderRequest

#pragma mark Private

- (NSURLRequest *)urlRequest
{
    return [NSURLRequest requestWithURL:self.URL];
}

- (BOOL)shouldRetryForResponse:(NSURLResponse *)response error:(NSError *)error
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        switch (httpResponse.statusCode) {
            case SPTDataLoaderRequestHTTPStatusCodeContinue:
            case SPTDataLoaderRequestHTTPStatusCodeSwitchProtocols:
            case SPTDataLoaderRequestHTTPStatusCodeOK:
            case SPTDataLoaderRequestHTTPStatusCodeCreated:
            case SPTDataLoaderRequestHTTPStatusCodeAccepted:
            case SPTDataLoaderRequestHTTPStatusCodeNonAuthoritiveInformation:
            case SPTDataLoaderRequestHTTPStatusCodeNoContent:
            case SPTDataLoaderRequestHTTPStatusCodeResetContent:
            case SPTDataLoaderRequestHTTPStatusCodePartialContent:
            case SPTDataLoaderRequestHTTPStatusCodeMovedMultipleChoices:
            case SPTDataLoaderRequestHTTPStatusCodeMovedPermanently:
            case SPTDataLoaderRequestHTTPStatusCodeFound:
            case SPTDataLoaderRequestHTTPStatusCodeSeeOther:
            case SPTDataLoaderRequestHTTPStatusCodeNotModified:
            case SPTDataLoaderRequestHTTPStatusCodeUseProxy:
            case SPTDataLoaderRequestHTTPStatusCodeUnused:
            case SPTDataLoaderRequestHTTPStatusCodeTemporaryRedirect:
            case SPTDataLoaderRequestHTTPStatusCodeBadRequest:
            case SPTDataLoaderRequestHTTPStatusCodeUnauthorised:
            case SPTDataLoaderRequestHTTPStatusCodePaymentRequired:
            case SPTDataLoaderRequestHTTPStatusCodeForbidden:
            case SPTDataLoaderRequestHTTPStatusCodeMethodNotAllowed:
            case SPTDataLoaderRequestHTTPStatusCodeNotAcceptable:
            case SPTDataLoaderRequestHTTPStatusCodeProxyAuthenticationRequired:
            case SPTDataLoaderRequestHTTPStatusCodeConflict:
            case SPTDataLoaderRequestHTTPStatusCodeGone:
            case SPTDataLoaderRequestHTTPStatusCodeLengthRequired: // We always include the content-length header
            case SPTDataLoaderRequestHTTPStatusCodePreconditionFailed:
            case SPTDataLoaderRequestHTTPStatusCodeRequestEntityTooLarge:
            case SPTDataLoaderRequestHTTPStatusCodeRequestURITooLong:
            case SPTDataLoaderRequestHTTPStatusCodeRequestRangeUnsatisifiable:
            case SPTDataLoaderRequestHTTPStatusCodeExpectationFail:
            case SPTDataLoaderRequestHTTPStatusCodeHTTPVersionNotSupported:
                return NO;
            case SPTDataLoaderRequestHTTPStatusCodeNotFound:
            case SPTDataLoaderRequestHTTPStatusCodeRequestTimeout:
            case SPTDataLoaderRequestHTTPStatusCodeUnsupportedMediaTypes:
            case SPTDataLoaderRequestHTTPStatusCodeInternalServerError:
            case SPTDataLoaderRequestHTTPStatusCodeNotImplemented:
            case SPTDataLoaderRequestHTTPStatusCodeBadGateway:
            case SPTDataLoaderRequestHTTPStatusCodeServiceUnavailable:
            case SPTDataLoaderRequestHTTPStatusCodeGatewayTimeout:
                return YES;
        }
    }
    
    if (![error.domain isEqualToString:NSURLErrorDomain]) {
        return NO;
    }
    
    if (error.code == NSURLErrorCancelled) {
        return NO;
    }
    
    switch (error.code) {
        case NSURLErrorCancelled:
        case NSURLErrorUnknown:
        case NSURLErrorBadURL:
        case NSURLErrorUnsupportedURL:
        case NSURLErrorZeroByteResource:
        case NSURLErrorCannotDecodeRawData:
        case NSURLErrorCannotDecodeContentData:
        case NSURLErrorCannotParseResponse:
        case NSURLErrorFileDoesNotExist:
        case NSURLErrorNoPermissionsToReadFile:
        case NSURLErrorDataLengthExceedsMaximum:
        case NSURLErrorRedirectToNonExistentLocation:
        case NSURLErrorBadServerResponse:
        case NSURLErrorUserCancelledAuthentication:
        case NSURLErrorUserAuthenticationRequired:
        case NSURLErrorServerCertificateHasBadDate:
        case NSURLErrorServerCertificateUntrusted:
        case NSURLErrorServerCertificateHasUnknownRoot:
        case NSURLErrorServerCertificateNotYetValid:
        case NSURLErrorClientCertificateRejected:
        case NSURLErrorClientCertificateRequired:
            return NO;
        
        case NSURLErrorTimedOut:
        case NSURLErrorCannotFindHost:
        case NSURLErrorCannotConnectToHost:
        case NSURLErrorNetworkConnectionLost:
        case NSURLErrorDNSLookupFailed:
        case NSURLErrorHTTPTooManyRedirects:
        case NSURLErrorResourceUnavailable:
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorSecureConnectionFailed:
        case NSURLErrorCannotLoadFromNetwork:
            return YES;
    }
    
    return NO;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    __typeof(self) copy = [self.class new];
    copy.URL = self.URL;
    copy.retryCount = self.retryCount;
    return copy;
}

@end
