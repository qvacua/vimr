/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBCacao.h>
#import "VRAppDelegate.h"


@implementation VRAppDelegate

TB_MANUALWIRE(workspace)

- (IBAction)showHelp:(id)sender {
    [self.workspace openURL:[[NSURL alloc] initWithString:@"http://vimdoc.sourceforge.net/htmldoc/"]];
}

- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    [[TBContext sharedContext] autowireSeed:self];

    return self;
}

#pragma mark NSApplicationDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

@end
