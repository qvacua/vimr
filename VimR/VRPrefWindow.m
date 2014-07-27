/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRPrefWindow.h"
#import "VRUtils.h"
#import "VRGeneralPrefPane.h"
#import "VRFileBrowserPrefPane.h"


NSString *const qPrefWindowFrameAutosaveName = @"pref-window-frame-autosave";


#define CONSTRAIN(fmt) [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]];


@implementation VRPrefWindow {
  NSArray *_prefPanes;
}

@autowire(userDefaultsController)

#pragma mark NSWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  self = [super initWithContentRect:contentRect styleMask:NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask backing:NSBackingStoreBuffered defer:YES];
  RETURN_NIL_WHEN_NOT_SELF

  self.title = @"Preferences";
  self.releasedWhenClosed = NO;
  [self setFrameAutosaveName:qPrefWindowFrameAutosaveName];

  return self;
}

#pragma mark TBInitializingBean
- (void)postConstruct {
  _prefPanes = @[
      [[VRGeneralPrefPane alloc] initWithUserDefaultsController:_userDefaultsController],
      [[VRFileBrowserPrefPane alloc] initWithUserDefaultsController:_userDefaultsController],
  ];

  for (NSView *prefPane in _prefPanes) {
    prefPane.translatesAutoresizingMaskIntoConstraints = NO;
  }

  [self addViews];
}

#pragma mark NSOutlineViewDataSource
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  return @"test";
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  return 10;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  return item;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  return NO;
}

#pragma mark Private
- (void)addViews {
  NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:@"name"];
  tableColumn.dataCell = [[NSTextFieldCell alloc] init];
  [tableColumn.dataCell setAllowsEditingTextAttributes:YES];
  [tableColumn.dataCell setLineBreakMode:NSLineBreakByTruncatingTail];

  NSOutlineView *categoryOutlineView = [[NSOutlineView alloc] initWithFrame:CGRectZero];
//  categoryOutlineView.translatesAutoresizingMaskIntoConstraints = NO;
  [categoryOutlineView addTableColumn:tableColumn];
  categoryOutlineView.outlineTableColumn = tableColumn;
  [categoryOutlineView sizeLastColumnToFit];
  categoryOutlineView.allowsEmptySelection = NO;
  categoryOutlineView.allowsMultipleSelection = NO;
  categoryOutlineView.headerView = nil;
  categoryOutlineView.focusRingType = NSFocusRingTypeNone;
  categoryOutlineView.dataSource = self;
  categoryOutlineView.delegate = self;
  categoryOutlineView.allowsMultipleSelection = NO;
  categoryOutlineView.allowsEmptySelection = NO;

  NSScrollView *categoryScrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
  categoryScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  categoryScrollView.hasVerticalScroller = YES;
  categoryScrollView.hasHorizontalScroller = YES;
  categoryScrollView.borderType = NSBezelBorder;
  categoryScrollView.autohidesScrollers = YES;
  categoryScrollView.documentView = categoryOutlineView;

  NSScrollView *paneScrollView = [[NSScrollView alloc] initWithFrame:CGRectZero];
  paneScrollView.translatesAutoresizingMaskIntoConstraints = NO;
  paneScrollView.hasVerticalScroller = YES;
  paneScrollView.hasHorizontalScroller = YES;
  paneScrollView.borderType = NSNoBorder;
  paneScrollView.autohidesScrollers = YES;
  paneScrollView.autoresizesSubviews = YES;
  paneScrollView.documentView = _prefPanes[0];
  paneScrollView.backgroundColor = [NSColor windowBackgroundColor];

  NSView *contentView = self.contentView;
  [contentView addSubview:categoryScrollView];
  [contentView addSubview:paneScrollView];

  NSDictionary *views = @{
      @"catView" : categoryScrollView,
      @"paneView" : paneScrollView,
  };

  [contentView addConstraint:[NSLayoutConstraint constraintWithItem:categoryScrollView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:150]];
  [contentView addConstraint:[NSLayoutConstraint constraintWithItem:paneScrollView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:200]];
  CONSTRAIN(@"H:|-(-1)-[catView][paneView]|")
  CONSTRAIN(@"V:|-(-1)-[catView]-(-1)-|")
  CONSTRAIN(@"V:|[paneView]|")
}

@end
