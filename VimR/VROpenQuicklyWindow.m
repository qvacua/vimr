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
#import "VRInactiveTableView.h"
#import "OakImageAndTextCell.h"
#import "ALView+PureLayout.h"


int qOpenQuicklyWindowPadding = 8;


@implementation VROpenQuicklyWindow {
  NSScrollView *_scrollView;
}

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect {
  self = [super initWithContentRect:contentRect
                          styleMask:NSTitledWindowMask | NSClosableWindowMask | NSTexturedBackgroundWindowMask
                            backing:NSBackingStoreBuffered
                              defer:YES];

  RETURN_NIL_WHEN_NOT_SELF

  self.hasShadow = YES;
  self.level = NSFloatingWindowLevel; // the window will hide when spaces is activated
  self.opaque = NO;
  self.movableByWindowBackground = NO;
  self.excludedFromWindowsMenu = YES;
  self.releasedWhenClosed = NO;
  self.title = @"Open Quickly";
  [self setAutorecalculatesContentBorderThickness:NO forEdge:NSMaxYEdge];
  [self setContentBorderThickness:22 forEdge:NSMaxYEdge];

  [self addViews];

  return self;
}

- (void)reset {
  self.searchField.stringValue = @"";
}

#pragma mark NSWindow
- (BOOL)canBecomeKeyWindow {
  // when an NSWindow has the style mask NSBorderlessWindowMask, then, by default, it cannot become key
  return YES;
}

#pragma mark Private
- (void)addViews {
  NSFont *smallSystemFont = [NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]];
  NSColor *clearColor = [NSColor clearColor];
  NSView *contentView = self.contentView;

  _itemCountTextField = [[NSTextField alloc] initForAutoLayout];
  _itemCountTextField.backgroundColor = clearColor;
  _itemCountTextField.alignment = NSRightTextAlignment;
  _itemCountTextField.stringValue = @"";
  _itemCountTextField.editable = NO;
  _itemCountTextField.bordered = NO;
  _itemCountTextField.font = smallSystemFont;
  [contentView addSubview:_itemCountTextField];

  _searchField = [[NSSearchField alloc] initForAutoLayout];
  [contentView addSubview:_searchField];

  NSTableColumn *tableColumn = [[NSTableColumn alloc] initWithIdentifier:@"name"];
  tableColumn.dataCell = [[OakImageAndTextCell alloc] init];
  [tableColumn.dataCell setLineBreakMode:NSLineBreakByTruncatingTail];

  _fileItemTableView = [[VRInactiveTableView alloc] initWithFrame:CGRectZero];
  [_fileItemTableView addTableColumn:tableColumn];
  _fileItemTableView.usesAlternatingRowBackgroundColors = YES;
  _fileItemTableView.allowsEmptySelection = NO;
  _fileItemTableView.allowsMultipleSelection = NO;
  _fileItemTableView.refusesFirstResponder = YES;
  _fileItemTableView.headerView = nil;
  _fileItemTableView.focusRingType = NSFocusRingTypeNone;

  _scrollView = [[NSScrollView alloc] initForAutoLayout];
  _scrollView.hasVerticalScroller = YES;
  _scrollView.hasHorizontalScroller = NO;
  _scrollView.borderType = NSBezelBorder;
  _scrollView.autohidesScrollers = YES;
  _scrollView.documentView = _fileItemTableView;
  [contentView addSubview:_scrollView];

  _pathControl = [[NSPathControl alloc] initForAutoLayout];
  _pathControl.pathStyle = NSPathStyleStandard;
  _pathControl.backgroundColor = [NSColor clearColor];
  _pathControl.refusesFirstResponder = YES;
  [_pathControl.cell setControlSize:NSSmallControlSize];
  [_pathControl.cell setFont:smallSystemFont];
  [_pathControl setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
  [contentView addSubview:_pathControl];

  [_searchField autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:qOpenQuicklyWindowPadding];
  [_searchField autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:qOpenQuicklyWindowPadding];
  [_scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:-1];
  [_scrollView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:-1];
  [_pathControl autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:2];
  [_itemCountTextField autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:_pathControl];
  [_itemCountTextField autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:6];

  [_searchField autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:qOpenQuicklyWindowPadding];
  [_scrollView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_searchField withOffset:qOpenQuicklyWindowPadding];
  [_itemCountTextField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:_scrollView withOffset:3];
  [_itemCountTextField autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:5];
  [_pathControl autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:1];
}

@end
