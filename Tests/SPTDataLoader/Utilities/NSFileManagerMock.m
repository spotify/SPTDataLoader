/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import "NSFileManagerMock.h"

@implementation NSFileManagerMock

- (BOOL)moveItemAtPath:(NSString *)srcPath
                toPath:(NSString *)dstPath
                 error:(NSError * _Nullable __autoreleasing *)error
{
    return YES;
}

- (BOOL)removeItemAtPath:(NSString *)path
                   error:(NSError * _Nullable __autoreleasing *)error
{
    return YES;
}

@end
