/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;


@interface NSObject (NeoVimServer)

@property (readonly, nonnull) const char *cdesc;

@end

@interface NSString (NeoVimServer)

@property (readonly, nonnull) const char *cstr;
@property (readonly) NSUInteger clength;

@end
