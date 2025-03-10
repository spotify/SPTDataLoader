/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDataMock : NSObject

+ (nullable NSData *)dataWithContentsOfFile:(NSString *)path
                                    options:(NSDataReadingOptions)readOptionsMask
                                      error:(NSError * __autoreleasing * _Nullable)errorPtr;

@end

NS_ASSUME_NONNULL_END
