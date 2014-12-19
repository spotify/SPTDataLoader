#import "NSDictionary+HeaderSize.h"

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
