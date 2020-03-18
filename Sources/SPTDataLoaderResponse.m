/*
 Copyright (c) 2015-2020 Spotify AB.

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
#import <SPTDataLoader/SPTDataLoaderResponse.h>

#import "SPTDataLoaderResponse+Private.h"

NS_ASSUME_NONNULL_BEGIN

NSString * const SPTDataLoaderResponseErrorDomain = @"com.sptdataloaderresponse.error";

static NSString * const SPTDataLoaderResponseHeaderRetryAfter = @"Retry-After";

@interface SPTDataLoaderResponse ()

@property (nonatomic, strong, readonly, nullable) NSURLResponse *response;
@property (nonatomic, strong, readwrite) NSDictionary<NSString *, NSString *> *responseHeaders;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) NSData *body;
@property (nonatomic, assign, readwrite) NSTimeInterval requestTime;

@end

@implementation SPTDataLoaderResponse

#pragma mark Private

+ (instancetype)dataLoaderResponseWithRequest:(SPTDataLoaderRequest *)request response:(nullable NSURLResponse *)response
{
    return [[self alloc] initWithRequest:request response:response];
}

- (instancetype)initWithRequest:(SPTDataLoaderRequest *)request response:(nullable NSURLResponse *)response
{
    self = [super init];
    if (self) {
        _request = request;
        _response = response;

        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode >= SPTDataLoaderResponseHTTPStatusCodeMovedMultipleChoices
                || httpResponse.statusCode <= SPTDataLoaderResponseHTTPStatusCodeSwitchProtocols) {
                _error = [NSError errorWithDomain:SPTDataLoaderResponseErrorDomain
                                             code:httpResponse.statusCode
                                         userInfo:nil];
            }
            _responseHeaders = httpResponse.allHeaderFields;
            _statusCode = httpResponse.statusCode;
        }

        _retryAfter = [self retryAfterForHeaders:_responseHeaders];
    }
    
    return self;
}

- (BOOL)shouldRetry
{
    if ([self.error.domain isEqualToString:SPTDataLoaderResponseErrorDomain]) {
        switch (self.error.code) {
            case SPTDataLoaderResponseHTTPStatusCodeInvalid:
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

- (nullable NSDate *)retryAfterForHeaders:(NSDictionary<NSString *, NSString *> *)headers
{
    static NSDateFormatter *httpDateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        httpDateFormatter = [NSDateFormatter new];
        [httpDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
    });
    
    NSTimeInterval retryAfterSeconds = [headers[SPTDataLoaderResponseHeaderRetryAfter] doubleValue];
    if (retryAfterSeconds != 0.0) {
        return [NSDate dateWithTimeIntervalSinceNow:retryAfterSeconds];
    }

    NSString *retryAfterValue = headers[SPTDataLoaderResponseHeaderRetryAfter];
    return [httpDateFormatter dateFromString:retryAfterValue];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p URL = \"%@\"; status-code = %ld; headers = %@>", self.class, (void *)self, self.response.URL, (long)self.statusCode, self.responseHeaders];
}


@end

NS_ASSUME_NONNULL_END
