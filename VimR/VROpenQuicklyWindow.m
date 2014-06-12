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
  NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectZero];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.backgroundColor = [NSColor clearColor];
  label.stringValue = @"Enter file name";
  label.editable = NO;
  label.bordered = NO;
  [self.contentView addSubview:label];

  _itemCountTextField = [[NSTextField alloc] initWithFrame:CGRectZero];
  _itemCountTextField.translatesAutoresizingMaskIntoConstraints = NO;
  _itemCountTextField.backgroundColor = [NSColor clearColor];
  _itemCountTextField.alignment = NSRightTextAlignment;
  _itemCountTextField.stringValue = @"";
  _itemCountTextField.editable = NO;
  _itemCountTextField.bordered = NO;
  [self.contentView addSubview:_itemCountTextField];

  _progressIndicator = [[NSProgressIndicator alloc] initWithFrame:CGRectZero];
  _progressIndicator.style = NSProgressIndicatorSpinningStyle;
  _progressIndicator.translatesAutoresizingMaskIntoConstraints = NO;
  _progressIndicator.controlSize = NSSmallControlSize;
  [self.contentView addSubview:_progressIndicator];

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

  NSTextField *workspaceLabel = [[NSTextField alloc] initWithFrame:CGRectZero];
  workspaceLabel.translatesAutoresizingMaskIntoConstraints = NO;
  workspaceLabel.backgroundColor = [NSColor clearColor];
  workspaceLabel.stringValue = @"Working Dir.:";
  workspaceLabel.editable = NO;
  workspaceLabel.bordered = NO;
  [self.contentView addSubview:workspaceLabel];

  _workspaceTextField = [[NSTextField alloc] initWithFrame:CGRectZero];
  _workspaceTextField.translatesAutoresizingMaskIntoConstraints = NO;
  [_workspaceTextField.cell setLineBreakMode:NSLineBreakByTruncatingHead];
  _workspaceTextField.backgroundColor = [NSColor clearColor];
  _workspaceTextField.alignment = NSLeftTextAlignment;
  _workspaceTextField.stringValue = @"";
  _workspaceTextField.editable = NO;
  _workspaceTextField.bordered = NO;
  [self.contentView addSubview:_workspaceTextField];

  NSDictionary *views = @{
      @"searchField" : _searchField,
      @"label" : label,
      @"progress" : _progressIndicator,
      @"table" : _scrollView,
      @"itemCount" : _itemCountTextField,
      @"workspaceLabel" : workspaceLabel,
      @"workspaceTextField" : _workspaceTextField,
  };

  CONSTRAIN(@"H:|-(padding)-[label]");
  CONSTRAIN(@"H:[progress]-(padding)-[itemCount]-(padding)-|");
  CONSTRAIN(@"H:|-(padding)-[searchField]-(padding)-|");
  CONSTRAIN(@"H:|-(-1)-[table]-(-1)-|");
  CONSTRAIN(@"H:|-(padding)-[workspaceLabel][workspaceTextField(>=50)]-(padding)-|");
  CONSTRAIN(@"V:|-(padding)-[label]-(padding)-[searchField]-(padding)-[table]-(3)-[workspaceLabel]-(5)-|");
  CONSTRAIN(@"V:|-(padding)-[itemCount]-(padding)-[searchField]-(padding)-[table]-(3)-[workspaceTextField]-(5)-|");
  CONSTRAIN(@"V:|-(padding)-[progress]-(padding)-[searchField]-(padding)-[table]-(3)-[workspaceTextField]-(5)-|");
}

@end
