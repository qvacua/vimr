/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VROpenQuicklyWindowController.h"
#import "VROpenQuicklyWindow.h"
#import "VRLog.h"


static const int qSearchFieldHeight = 22;
int qOpenQuicklyWindowWidth = 200;

@implementation VROpenQuicklyWindowController

#pragma mark Public
- (void)showWindowForContentRect:(CGRect)contentRect {
    CGFloat xPos = NSMinX(contentRect) + NSWidth(contentRect) / 2 - qOpenQuicklyWindowWidth / 2
            - 2 * qOpenQuicklyWindowPadding;
    CGFloat yPos = NSMaxY(contentRect) - qSearchFieldHeight - 2 * qOpenQuicklyWindowPadding;

    self.window.frameOrigin = CGPointMake(xPos, yPos);
    [self.window makeKeyAndOrderFront:self];
}

#pragma mark NSObject
- (id)init {
    VROpenQuicklyWindow *win = [[VROpenQuicklyWindow alloc] initWithContentRect:
            CGRectMake(100, 100, qOpenQuicklyWindowWidth, 100)];

    self = [super initWithWindow:win];
    if (!self) {
        return nil;
    }

    win.delegate = self;
    win.searchField.delegate = self;

    return self;
}

#pragma mark NSTextFieldDelegate
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
    if (selector == @selector(cancelOperation:)) {
        log4Debug(@"Open quickly cancelled");

        [self reset];
        return YES;
    }

    if (selector == @selector(insertNewline:)) {
        log4Debug(@"Open quickly window: Enter pressed");

        return YES;
    }

    return NO;
}

#pragma mark NSWindowDelegate
- (void)windowDidResignMain:(NSNotification *)notification {
    log4Debug(@"Open quickly window resigned main");
    [self reset];
}

- (void)windowDidResignKey:(NSNotification *)notification {
    log4Debug(@"Open quickly window resigned key");
    [self reset];
}

#pragma mark Private
- (void)reset {
    [self.window orderBack:self];
    [(VROpenQuicklyWindow *) self.window reset];
}

@end
