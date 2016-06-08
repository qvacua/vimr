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

@protocol NeoVimUiBridgeProtocol <NSObject>

/**
 * NeoVim has set the size of its screen to rows X columns. The view must be resized accordingly.
 */
- (void)resizeToWidth:(int)width height:(int)height;

/**
 * Clear the view completely. In subsequent callbacks, eg by put, NeoVim will tell us what to do to completely redraw
 * the view.
 */
- (void)clear;

/**
 * End of line is met. The view can fill the rest of the line with the background color.
 */
- (void)eolClear;

/**
 * Move the current cursor to (row, column). This can mean two things:
 * 1. NeoVim wants to put, ie draw, at (row, column) or
 * 2. NeoVim wants to put the cursor at (row, column).
 * In case of 1. NeoVim will put in subsequent call. In case of 2. NeoVim seems to flush twice in a row.
 */
- (void)cursorGotoRow:(int)row column:(int)column;

- (void)updateMenu;
- (void)busyStart;
- (void)busyStop;
- (void)mouseOn;
- (void)mouseOff;

/**
 * Mode changed to mode, cf vim.h.
 */
- (void)modeChange:(int)mode;

- (void)setScrollRegionToTop:(int)top bottom:(int)bottom left:(int)left right:(int)right;
- (void)scroll:(int)count;
- (void)highlightSet:(HighlightAttributes)attrs;

/**
 * Draw string at the current cursor which was set by a previous cursorGotoRow:column callback.
 */
- (void)put:(NSString *)string;

- (void)bell;
- (void)visualBell;
- (void)flush;

/**
 * Set the foreground color.
 */
- (void)updateForeground:(int)fg;

/**
 * Set the background color.
 */
- (void)updateBackground:(int)bg;

- (void)updateSpecial:(int)sp;
- (void)suspend;
- (void)setTitle:(NSString *)title;
- (void)setIcon:(NSString *)icon;

/**
 * NeoVim has been stopped.
 */
- (void)stop;

@end
