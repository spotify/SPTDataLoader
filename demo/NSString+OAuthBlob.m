/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "NSString+OAuthBlob.h"
#import "ClientKeys.h"

@implementation NSString (OAuthBlob)

+ (instancetype)spt_OAuthBlob
{
    NSString *authorisationCode = [@[ SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET ] componentsJoinedByString:@":"];
    NSString *encodedAuthorisationCode = [[authorisationCode dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)(NSDataBase64EncodingEndLineWithCarriageReturn | NSDataBase64EncodingEndLineWithLineFeed)];
    return encodedAuthorisationCode;
}

@end
