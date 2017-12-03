/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

#import "NeoVimAutoCommandEvent.generated.h"


// Keep in sync with ModeShape enum in cursor_shape.h.
typedef NS_ENUM(NSUInteger, CursorModeShape) {
  CursorModeShapeNormal = 0,
  CursorModeShapeVisual = 1,
  CursorModeShapeInsert = 2,
  CursorModeShapeReplace = 3,
  CursorModeShapeCmdline = 4,
  CursorModeShapeCmdlineInsert = 5,
  CursorModeShapeCmdlineReplace = 6,
  CursorModeShapeOperatorPending = 7,
  CursorModeShapeVisualExclusive = 8,
  CursorModeShapeOnCmdline = 9,
  CursorModeShapeOnStatusLine = 10,
  CursorModeShapeDraggingStatusLine = 11,
  CursorModeShapeOnVerticalSepLine = 12,
  CursorModeShapeDraggingVerticalSepLine = 13,
  CursorModeShapeMore = 14,
  CursorModeShapeMoreLastLine = 15,
  CursorModeShapeShowingMatchingParen = 16,
  CursorModeShapeTermFocus = 17,
  CursorModeShapeCount = 18,
};

extern NSString * __nonnull cursorModeShapeName(CursorModeShape mode);

typedef NS_ENUM(NSUInteger, FontTrait) {
    FontTraitNone      = 0,
    FontTraitItalic    = (1 << 0),
    FontTraitBold      = (1 << 1),
    FontTraitUnderline = (1 << 2),
    FontTraitUndercurl = (1 << 3)
};

typedef struct {
    FontTrait fontTrait;

    NSInteger foreground;
    NSInteger background;
    NSInteger special;
} CellAttributes;

typedef struct {
  NSInteger row;
  NSInteger column;
} Position;

NS_ASSUME_NONNULL_BEGIN

@protocol NeoVimUiBridgeProtocol <NSObject>

/**
 * NeoVim has set the size of its screen to rows X columns. The view must be resized accordingly.
 */
- (void)resizeToWidth:(NSInteger)width height:(NSInteger)height;

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
- (void)gotoPosition:(Position)position textPosition:(Position)textPosition;

- (void)updateMenu;
- (void)busyStart;
- (void)busyStop;
- (void)mouseOn;
- (void)mouseOff;

/**
 * Mode changed to mode, cf vim.h.
 */
- (void)modeChange:(CursorModeShape)mode;

- (void)setScrollRegionToTop:(NSInteger)top bottom:(NSInteger)bottom left:(NSInteger)left right:(NSInteger)right;
- (void)scroll:(NSInteger)count;
- (void)highlightSet:(CellAttributes)attrs;

/**
 * Draw string at the current cursor which was set by a previous cursorGotoRow:column callback.
 */
- (void)put:(NSString *)string;

- (void)putMarkedText:(NSString *)markedText;
- (void)unmarkRow:(NSInteger)row column:(NSInteger)column;

- (void)bell;
- (void)visualBell;
- (void)flush;

/**
 * Set the default foreground color.
 */
- (void)updateForeground:(NSInteger)fg;

/**
 * Set the default background color.
 */
- (void)updateBackground:(NSInteger)bg;

/**
 * Set the default special color, eg curly underline for spelling errors.
 */
- (void)updateSpecial:(NSInteger)sp;

- (void)suspend;
- (void)setTitle:(NSString *)title;
- (void)setIcon:(NSString *)icon;
- (void)setDirtyStatus:(bool)dirty;
- (void)cwdChanged:(NSString *)cwd;
- (void)colorSchemeChanged:(NSArray <NSNumber *> *)values;
- (void)autoCommandEvent:(NeoVimAutoCommandEvent)event bufferHandle:(NSInteger)bufferHandle;

/**
 * NeoVim has been stopped.
 */
- (void)stop;

- (void)ipcBecameInvalid:(NSString *)reason;

@end

NS_ASSUME_NONNULL_END
