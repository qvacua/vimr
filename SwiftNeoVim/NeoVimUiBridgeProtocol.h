/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;


typedef NS_ENUM(NSUInteger, Mode) {
    Normal    = 0x01,
    Visual    = 0x02,
    Cmdline   = 0x08,
    Insert    = 0x10,
    Replace   = 0x50,
};

typedef NS_ENUM(NSUInteger, FontTrait) {
    FontTraitNone      = 0,
    FontTraitItalic    = (1 << 0),
    FontTraitBold      = (1 << 1),
    FontTraitUnderline = (1 << 2),
    FontTraitUndercurl = (1 << 3)
};

typedef struct {
    FontTrait fontTrait;

    unsigned int foreground;
    unsigned int background;
    unsigned int special;
} CellAttributes;

typedef struct {
  NSInteger row;
  NSInteger column;
} Position;

#define qDefaultForeground 0xFF000000
#define qDefaultBackground 0xFFFFFFFF
#define qDefaultSpecial    0xFFFF0000

NS_ASSUME_NONNULL_BEGIN

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
- (void)gotoPosition:(Position)position screenCursor:(Position)screenCursor;

- (void)updateMenu;
- (void)busyStart;
- (void)busyStop;
- (void)mouseOn;
- (void)mouseOff;

/**
 * Mode changed to mode, cf vim.h.
 */
- (void)modeChange:(Mode)mode;

- (void)setScrollRegionToTop:(int)top bottom:(int)bottom left:(int)left right:(int)right;
- (void)scroll:(int)count;
- (void)highlightSet:(CellAttributes)attrs;

/**
 * Draw string at the current cursor which was set by a previous cursorGotoRow:column callback.
 */
- (void)put:(NSString *)string screenCursor:(Position)screenCursor;

- (void)putMarkedText:(NSString *)markedText screenCursor:(Position)screenCursor;
- (void)unmarkRow:(int)row column:(int)column;

- (void)bell;
- (void)visualBell;
- (void)flush;

/**
 * Set the default foreground color.
 */
- (void)updateForeground:(int)fg dark:(bool)dark;

/**
 * Set the default background color.
 */
- (void)updateBackground:(int)bg dark:(bool)dark;

/**
 * Set the default special color, eg curly underline for spelling errors.
 */
- (void)updateSpecial:(int)sp dark:(bool)dark;

- (void)suspend;
- (void)setTitle:(NSString *)title;
- (void)setIcon:(NSString *)icon;
- (void)setDirtyStatus:(bool)dirty;
- (void)cwdChanged;

/**
 * NeoVim has been stopped.
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
