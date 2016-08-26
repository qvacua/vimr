/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "CocoaCategories.h"

@implementation NSObject (NeoVimServer)

- (const char *)cdesc {
  return self.description.cstr;
}

@end

@implementation NSString (NeoVimServer)

- (const char *)cstr {
  return [self cStringUsingEncoding:NSUTF8StringEncoding];
}

@end
