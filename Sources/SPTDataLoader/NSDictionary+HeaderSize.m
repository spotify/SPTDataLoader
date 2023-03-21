/*
 Copyright 2015-2023 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "NSDictionary+HeaderSize.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSDictionary (HeaderSize)

- (NSInteger)spt_byteSizeOfHeaders
{
    NSInteger headerSize = 0;
    for (id key in self) {
        if (![key isKindOfClass:[NSString class]]) {
            continue;
        }
        
        NSString *keyString = (NSString *)key;
        id object = self[keyString];
        if (![object isKindOfClass:[NSString class]]) {
            continue;
        }
        
        NSString *objectString = (NSString *)object;
        headerSize += [keyString dataUsingEncoding:NSUTF8StringEncoding].length;
        headerSize += [@": \n" dataUsingEncoding:NSUTF8StringEncoding].length;
        headerSize += [objectString dataUsingEncoding:NSUTF8StringEncoding].length;
    }
    return headerSize;
}

@end

NS_ASSUME_NONNULL_END
