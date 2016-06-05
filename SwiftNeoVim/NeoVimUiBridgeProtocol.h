/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

// TODO: keep in sync with HlAttrs struct in ui.h
typedef struct {
  bool bold, underline, undercurl, italic, reverse;
  int foreground, background, special;
} HighlightAttributes;

@protocol NeoVimUiBridgeProtocol

- (void)resizeToRows:(int)rows columns:(int)columns;
- (void)clear;
- (void)eolClear;
- (void)cursorGotoRow:(int)row column:(int)column;
- (void)updateMenu;
- (void)busyStart;
- (void)busyStop;
- (void)mouseOn;
- (void)mouseOff;
- (void)modeChange:(int)mode;
- (void)setScrollRegionToTop:(int)top bottom:(int)bottom left:(int)left right:(int)right;
- (void)scroll:(int)count;
- (void)highlightSet:(HighlightAttributes)attrs;
- (void)put:(NSString *)string;
- (void)bell;
- (void)visualBell;
- (void)flush;
- (void)updateForeground:(int)fg;
- (void)updateBackground:(int)bg;
- (void)updateSpecial:(int)sp;
- (void)suspend;
- (void)setTitle:(NSString *)title;
- (void)setIcon:(NSString *)icon;
- (void)stop;

@end