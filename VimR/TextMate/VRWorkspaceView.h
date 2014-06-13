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

@property (nonatomic) VRFileBrowserView *fileBrowserView;
@property (nonatomic) MMVimView *vimView;
@property (nonatomic) BOOL fileBrowserOnRight;
@property (nonatomic) CGFloat fileBrowserWidth;
@property (nonatomic, readonly) CGFloat sidebarAndDividerWidth;
@property (nonatomic, readonly) CGFloat defaultFileBrowserAndDividerWidth;
@property (nonatomic) NSUInteger dragIncrement;

@end
