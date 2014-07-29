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


int qOpenQuicklyWindowPadding = 8;


#define CONSTRAIN(fmt) [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:@{@"padding":@(qOpenQuicklyWindowPadding)} views:views]];


@implementation VROpenQuicklyWindow {
  NSScrollView *_scrollView;
}

#pragma mark Public
- (instancetype)initWithContentRect:(CGRect)contentRect {
  self = [super initWithContentRect:contentRect styleMask:NSTitledWindowMask | NSClosableWindowMask
      | NSTexturedBackgroundWindowMask
                            backing:NSBackingStoreBuffered defer:YES];
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

  _itemCountTextField = [[NSTextField alloc] initWithFrame:CGRectZero];
  _itemCountTextField.translatesAutoresizingMaskIntoConstraints = NO;
  _itemCountTextField.backgroundColor = clearColor;
  _itemCountTextField.alignment = NSRightTextAlignment;
  _itemCountTextField.stringValue = @"";
  _itemCountTextField.editable = NO;
  _itemCountTextField.bordered = NO;
  _itemCountTextField.font = smallSystemFont;
  [contentView addSubview:_itemCountTextField];

  _searchField = [[NSSearchField alloc] initWithFrame:CGRectZero];
  _searchField.translatesAutoresizingMaskIntoConstraints = NO;
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

  _scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
  _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
  _scrollView.hasVerticalScroller = YES;
  _scrollView.hasHorizontalScroller = NO;
  _scrollView.borderType = NSBezelBorder;
  _scrollView.autohidesScrollers = YES;
  _scrollView.documentView = _fileItemTableView;
  [contentView addSubview:_scrollView];

  _pathControl = [[NSPathControl alloc] initWithFrame:CGRectZero];
  _pathControl.translatesAutoresizingMaskIntoConstraints = NO;
  _pathControl.pathStyle = NSPathStyleStandard;
  _pathControl.backgroundColor = [NSColor clearColor];
  _pathControl.refusesFirstResponder = YES;
  [_pathControl.cell setControlSize:NSSmallControlSize];
  [_pathControl.cell setFont:smallSystemFont];
  [_pathControl setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
  [contentView addSubview:_pathControl];

  NSDictionary *views = @{
      @"searchField" : _searchField,
      @"table" : _scrollView,
      @"workspace" : _pathControl,
      @"count" : _itemCountTextField,
  };

  CONSTRAIN(@"H:|-(padding)-[searchField]-(padding)-|")
  CONSTRAIN(@"H:|-(-1)-[table]-(-1)-|")
  CONSTRAIN(@"H:|-(2)-[workspace]-[count]-(6)-|")

  CONSTRAIN(@"V:|-(padding)-[searchField]-(padding)-[table]-(3)-[count]-(5)-|");
  CONSTRAIN(@"V:[workspace]-(1)-|")
}

@end
