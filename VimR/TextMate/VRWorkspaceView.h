/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@class MMVimView;
@class VRFileBrowserView;

/**
* Copied and modified from TextMate -Tae
*
* Frameworks/DocumentWindow/src/ProjectLayoutView.mm
* v2.0-alpha.9537
*/
@interface VRWorkspaceView : NSView

@property VRFileBrowserView *fileBrowserView;
@property MMVimView *vimView;
@property BOOL fileBrowserOnRight;

@end
