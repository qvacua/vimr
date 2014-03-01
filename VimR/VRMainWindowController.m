/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRMainWindowController.h"


@interface VRMainWindowController ()

@end

@implementation VRMainWindowController

#pragma mark NSWindowController
- (instancetype)initWithWindow:(NSWindow *)window {
    self = [super initWithWindow:window];

    if (self == nil) {
        return nil;
    }

    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
}

@end
