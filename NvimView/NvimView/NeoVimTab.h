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
@property (nonatomic, readonly) bool isCurrent;

- (instancetype)initWithHandle:(NSInteger)handle windows:(NSArray <NeoVimWindow *> *)windows current:(bool)current;

/// @returns The most recently selected window in *this* tab.
- (NeoVimWindow * _Nullable )currentWindow;

- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
