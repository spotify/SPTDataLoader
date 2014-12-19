#import <Foundation/Foundation.h>

/**
 * A category for calculating the size of a header represented by an NSDictionary
 */
@interface NSDictionary (HeaderSize)

/**
 * The size of the header in bytes represented by the dictionary
 */
- (NSInteger)spt_byteSizeOfHeaders;

@end
