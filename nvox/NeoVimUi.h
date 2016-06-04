/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

@protocol NeoVimUi

- (void)resize:(int)rows columns:(int)columns;
- (void)clear;
- (void)eolClear;
- (void)cursorGoto:(int)row column:(int)column;
- (void)updateMenu;
- (void)busyStart;
- (void)busyStop;
- (void)mouseOn;
- (void)mouseOff;
- (void)modeChange:(int)mode;
- (void)setScrollRegion:(int)top bottom:(int)bottom left:(int)left right:(int)right;
- (void)scroll:(int)count;
- (void)highlightSet;
- (void)put:(NSString *)string;
- (void)bell;
- (void)visualBell;
- (void)flush;
- (void)updateFg:(int)fg;
- (void)updateBg:(int)bg;
- (void)updateSp:(int)sp;
- (void)suspend;
- (void)setTitle:(NSString *)title;
- (void)setIcon:(NSString *)icon;
- (void)stop;

@end