/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

#import "SharedTypes.h"
#import "NvimAutoCommandEvent.generated.h"


NS_ASSUME_NONNULL_BEGIN

@protocol NvimUiBridgeProtocol <NSObject>

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

- (void)unmarkRow:(NSInteger)row column:(NSInteger)column;

- (void)bell;
- (void)visualBell;
- (void)flush:(NSArray <NSData *> *)renderData;

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
- (void)autoCommandEvent:(NvimAutoCommandEvent)event bufferHandle:(NSInteger)bufferHandle;

/**
 * NeoVim has been stopped.
 */
- (void)stop;

- (void)ipcBecameInvalid:(NSString *)reason;

@end

NS_ASSUME_NONNULL_END
