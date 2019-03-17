/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "CocoaCategories.h"

@implementation NSString (NeoVimServer)

- (const char *)cstr {
  return [self cStringUsingEncoding:NSUTF8StringEncoding];
}

- (NSUInteger)clength {
  return [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
}

@end
