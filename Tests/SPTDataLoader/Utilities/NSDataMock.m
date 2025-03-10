/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "NSDataMock.h"

@implementation NSDataMock

+ (nullable NSData *)dataWithContentsOfFile:(NSString *)path
                                    options:(NSDataReadingOptions)readOptionsMask
                                      error:(NSError * __autoreleasing * _Nullable)errorPtr
{
    return [path dataUsingEncoding:NSUTF8StringEncoding];
}

@end
