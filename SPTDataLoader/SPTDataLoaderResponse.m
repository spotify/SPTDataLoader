#import <SPTDataLoader/SPTDataLoaderResponse.h>

#import "SPTDataLoaderResponse+Private.h"

NSString * const SPTDataLoaderResponseErrorDomain = @"com.sptdataloaderresponse.error";

static NSString * const SPTDataLoaderResponseHeaderRetryAfter = @"Retry-After";

@interface SPTDataLoaderResponse ()

@property (nonatomic, strong, readonly) NSURLResponse *response;
@property (nonatomic, strong, readwrite) NSDictionary *headers;
@property (nonatomic, strong, readwrite) NSError *error;

@end

@implementation SPTDataLoaderResponse

#pragma mark Private

+ (instancetype)dataLoaderResponseWithRequest:(SPTDataLoaderRequest *)request response:(NSURLResponse *)response
{
    return [[self alloc] initWithRequest:request response:response];
}

- (instancetype)initWithRequest:(SPTDataLoaderRequest *)request response:(NSURLResponse *)response
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _request = request;
    _response = response;
    
    _error = [self errorForResponse:response];
    _headers = [self headersForResponse:response];
    _retryAfter = [self retryAfterForHeaders:_headers];
    
    return self;
}

- (BOOL)shouldRetry
{
    if ([self.error.domain isEqualToString:SPTDataLoaderResponseErrorDomain]) {
        switch (self.error.code) {
            case SPTDataLoaderResponseHTTPStatusCodeContinue:
            case SPTDataLoaderResponseHTTPStatusCodeSwitchProtocols:
            case SPTDataLoaderResponseHTTPStatusCodeOK:
            case SPTDataLoaderResponseHTTPStatusCodeCreated:
            case SPTDataLoaderResponseHTTPStatusCodeAccepted:
            case SPTDataLoaderResponseHTTPStatusCodeNonAuthoritiveInformation:
            case SPTDataLoaderResponseHTTPStatusCodeNoContent:
            case SPTDataLoaderResponseHTTPStatusCodeResetContent:
            case SPTDataLoaderResponseHTTPStatusCodePartialContent:
            case SPTDataLoaderResponseHTTPStatusCodeMovedMultipleChoices:
            case SPTDataLoaderResponseHTTPStatusCodeMovedPermanently:
            case SPTDataLoaderResponseHTTPStatusCodeFound:
            case SPTDataLoaderResponseHTTPStatusCodeSeeOther:
            case SPTDataLoaderResponseHTTPStatusCodeNotModified:
            case SPTDataLoaderResponseHTTPStatusCodeUseProxy:
            case SPTDataLoaderResponseHTTPStatusCodeUnused:
            case SPTDataLoaderResponseHTTPStatusCodeTemporaryRedirect:
            case SPTDataLoaderResponseHTTPStatusCodeBadRequest:
            case SPTDataLoaderResponseHTTPStatusCodeUnauthorised:
            case SPTDataLoaderResponseHTTPStatusCodePaymentRequired:
            case SPTDataLoaderResponseHTTPStatusCodeForbidden:
            case SPTDataLoaderResponseHTTPStatusCodeMethodNotAllowed:
            case SPTDataLoaderResponseHTTPStatusCodeNotAcceptable:
            case SPTDataLoaderResponseHTTPStatusCodeProxyAuthenticationRequired:
            case SPTDataLoaderResponseHTTPStatusCodeConflict:
            case SPTDataLoaderResponseHTTPStatusCodeGone:
            case SPTDataLoaderResponseHTTPStatusCodeLengthRequired: // We always include the content-length header
            case SPTDataLoaderResponseHTTPStatusCodePreconditionFailed:
            case SPTDataLoaderResponseHTTPStatusCodeRequestEntityTooLarge:
            case SPTDataLoaderResponseHTTPStatusCodeRequestURITooLong:
            case SPTDataLoaderResponseHTTPStatusCodeRequestRangeUnsatisifiable:
            case SPTDataLoaderResponseHTTPStatusCodeExpectationFail:
            case SPTDataLoaderResponseHTTPStatusCodeHTTPVersionNotSupported:
            case SPTDataLoaderResponseHTTPStatusCodeNotImplemented:
                return NO;
            case SPTDataLoaderResponseHTTPStatusCodeNotFound:
            case SPTDataLoaderResponseHTTPStatusCodeRequestTimeout:
            case SPTDataLoaderResponseHTTPStatusCodeUnsupportedMediaTypes:
            case SPTDataLoaderResponseHTTPStatusCodeInternalServerError:
            case SPTDataLoaderResponseHTTPStatusCodeBadGateway:
            case SPTDataLoaderResponseHTTPStatusCodeServiceUnavailable:
            case SPTDataLoaderResponseHTTPStatusCodeGatewayTimeout:
                return YES;
        }
    }
    
    if ([self.error.domain isEqualToString:NSURLErrorDomain]) {
        switch (self.error.code) {
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
    }
    
    return NO;
}

- (NSError *)errorForResponse:(NSURLResponse *)response
{
    if (![self.response isKindOfClass:[NSHTTPURLResponse class]]) {
        return nil;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode < SPTDataLoaderResponseHTTPStatusCodeBadRequest) {
        return nil;
    }
    
    return [NSError errorWithDomain:SPTDataLoaderResponseErrorDomain code:httpResponse.statusCode userInfo:nil];
}

- (NSDictionary *)headersForResponse:(NSURLResponse *)response
{
    if (![self.response isKindOfClass:[NSHTTPURLResponse class]]) {
        return nil;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    return httpResponse.allHeaderFields;
}

- (NSDate *)retryAfterForHeaders:(NSDictionary *)headers
{
    static NSDateFormatter *httpDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        httpDateFormatter = [NSDateFormatter new];
        [httpDateFormatter setDateFormat:@"EEE',' dd' 'MMM' 'yyyy' HH':'mm':'ss zzz"];
    });
    
    NSTimeInterval retryAfterSeconds = [headers[SPTDataLoaderResponseHeaderRetryAfter] doubleValue];
    if (retryAfterSeconds != 0.0) {
        return [NSDate dateWithTimeIntervalSinceNow:retryAfterSeconds];
    }
    
    return [httpDateFormatter dateFromString:headers[SPTDataLoaderResponseHeaderRetryAfter]];
}

@end
