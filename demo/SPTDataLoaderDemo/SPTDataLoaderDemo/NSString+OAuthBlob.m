#import "NSString+OAuthBlob.h"

@implementation NSString (OAuthBlob)

+ (instancetype)spt_OAuthBlob
{
    NSString *clientID = @"INSERT_YOUR_CLIENT_ID";
    NSString *clientSecret = @"INSERT_YOUR_CLIENT_SECRET";
    NSString *authorisationCode = [@[ clientID, clientSecret ] componentsJoinedByString:@":"];
    NSString *encodedAuthorisationCode = [[authorisationCode dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    return encodedAuthorisationCode;
}

@end
