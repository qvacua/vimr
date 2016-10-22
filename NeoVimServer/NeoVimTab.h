/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;


@class NeoVimWindow;


NS_ASSUME_NONNULL_BEGIN

@interface NeoVimTab : NSObject <NSCoding>

@property (nonatomic, readonly) NSInteger handle;
@property (nonatomic, readonly) NSArray <NeoVimWindow *> *windows;

- (instancetype)initWithHandle:(NSInteger)handle windows:(NSArray <NeoVimWindow *> *)windows;

- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
