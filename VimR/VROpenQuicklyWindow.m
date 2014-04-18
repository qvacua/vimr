/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VROpenQuicklyWindow.h"
#import "VRUtils.h"


int qOpenQuicklyWindowPadding = 4;
int qOpenQuicklySearchFieldMinWidth = 100;

@implementation VROpenQuicklyWindow

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect {
    // this window should have a fixed height
    contentRect.size.height = 22 + 2 * qOpenQuicklyWindowPadding;

    self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered
                                defer:YES];
    RETURN_NIL_WHEN_NOT_SELF

    self.hasShadow = YES;
    self.opaque = NO;
    self.movableByWindowBackground = NO;
    self.excludedFromWindowsMenu = YES;
    self.backgroundColor = [NSColor controlColor];

    [self addViews];

    return self;
}

- (void)reset {
    [self.searchField setStringValue:@""];
}

#pragma mark NSWindow
- (BOOL)canBecomeKeyWindow {
    // when an NSWindow has the style mask NSBorderlessWindowMask, then, by default, it cannot become key
    return YES;
}

#pragma mark Private
- (void)addViews {
    _searchField = [[NSSearchField alloc] initWithFrame:CGRectZero];
    _searchField.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:_searchField];

    NSDictionary *views = @{
            @"searchField" : _searchField,
    };
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
            SF(@"H:|-%d-[searchField(>=%d)]-%d-|", qOpenQuicklyWindowPadding, qOpenQuicklySearchFieldMinWidth,
            qOpenQuicklyWindowPadding)
                                                                             options:0 metrics:nil views:views]
    ];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:
            SF(@"V:|-%d-[searchField]-%d-|", qOpenQuicklyWindowPadding, qOpenQuicklyWindowPadding)
                                                                             options:0 metrics:nil
                                                                               views:views]
    ];
}

@end
