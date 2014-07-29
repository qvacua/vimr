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
  [self setContentBorderThickness:25 forEdge:NSMaxYEdge];

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

  _itemCountTextField = [[NSTextField alloc] initWithFrame:CGRectZero];
  _itemCountTextField.translatesAutoresizingMaskIntoConstraints = NO;
  _itemCountTextField.backgroundColor = clearColor;
  _itemCountTextField.alignment = NSRightTextAlignment;
  _itemCountTextField.stringValue = @"";
  _itemCountTextField.editable = NO;
  _itemCountTextField.bordered = NO;
  _itemCountTextField.font = smallSystemFont;
  [self.contentView addSubview:_itemCountTextField];

  _searchField = [[NSSearchField alloc] initWithFrame:CGRectZero];
  _searchField.translatesAutoresizingMaskIntoConstraints = NO;
  [self.contentView addSubview:_searchField];

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
  [self.contentView addSubview:_scrollView];

  _workspaceTextField = [[NSTextField alloc] initWithFrame:CGRectZero];
  _workspaceTextField.translatesAutoresizingMaskIntoConstraints = NO;
  [_workspaceTextField.cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
  _workspaceTextField.backgroundColor = clearColor;
  _workspaceTextField.alignment = NSLeftTextAlignment;
  _workspaceTextField.stringValue = @"";
  _workspaceTextField.editable = NO;
  _workspaceTextField.bordered = NO;
  _workspaceTextField.font = smallSystemFont;
  [self.contentView addSubview:_workspaceTextField];

  NSDictionary *views = @{
      @"searchField" : _searchField,
      @"table" : _scrollView,
      @"workspace" : _workspaceTextField,
      @"count" : _itemCountTextField,
  };

  CONSTRAIN(@"H:|-(padding)-[searchField]-(padding)-|")
  CONSTRAIN(@"H:|-(-1)-[table]-(-1)-|")
  CONSTRAIN(@"H:|-(padding)-[workspace]-[count]-(padding)-|")

  CONSTRAIN(@"V:|-(padding)-[searchField]-(padding)-[table]-(3)-[workspace]-(5)-|");
  CONSTRAIN(@"V:[count]-(5)-|")
}

@end
