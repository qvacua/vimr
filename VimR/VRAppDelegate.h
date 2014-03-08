/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@interface VRAppDelegate : NSObject <NSApplicationDelegate>

@property (weak) NSWorkspace *workspace;
@property (assign) IBOutlet NSWindow *window;

- (IBAction)showHelp:(id)sender;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

@end
