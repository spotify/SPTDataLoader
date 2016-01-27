/*
 * Copyright (c) 2015-2016 Spotify AB.
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
@import Foundation;

/// http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
typedef NS_ENUM(NSInteger, SPTDataLoaderResponseHTTPStatusCode) {
    SPTDataLoaderResponseHTTPStatusCodeInvalid = 0,
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
 * The request object that generated the response
 */
@property (nonatomic, strong, readonly) SPTDataLoaderRequest *request;
/**
 * The error that the request generated
 * @warning Will be nil if the request is considered a success
 */
@property (nonatomic, strong, readonly) NSError *error;
/**
 * The headers that the server returned with a request
 */
@property (nonatomic, strong, readonly) NSDictionary *responseHeaders;
/**
 * The date at which the request that generated the response can be retried
 * @warning Can be nil if no retry-after is given in the response headers
 * @discussion This should only show up if the response is an error. It can still show up in a successful response, but
 * if this occurs it is probably the result of a misconfigured server
 */
@property (nonatomic, strong, readonly) NSDate *retryAfter;
/**
 * The body of data contained in the response
 * @warning Will be nil if not body was contained in the response
 */
@property (nonatomic, strong, readonly) NSData *body;
/**
 * The time the request took
 */
@property (nonatomic, assign, readonly) NSTimeInterval requestTime;
/**
 * The status code of the response
 * @discussion This value does not change depending on the error value
 */
@property (nonatomic, assign, readonly) SPTDataLoaderResponseHTTPStatusCode statusCode;

@end
