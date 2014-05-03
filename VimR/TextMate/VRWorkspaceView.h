/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>

/**
* Copied and modified -Tae
*
* Frameworks/DocumentWindow/src/ProjectLayoutView.mm
* v2.0-alpha.9537
*/
@interface VRWorkspaceView : NSView

@property NSView *fileBrowserView;
@property NSView *documentView;
@property CGFloat fileBrowserWidth;
@property BOOL fileBrowserOnRight;

@property NSUInteger increment;

@end
