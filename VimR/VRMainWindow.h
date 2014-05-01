/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@interface VRMainWindow : NSWindow

#pragma mark NSWindow
- (id)windowController;
- (IBAction)performClose:(id)sender;

@end
