/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBCacao.h>
#import "VROpenQuicklyWindowController.h"
#import "VROpenQuicklyWindow.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"
#import "VRScoredPath.h"
#import "VRFilterItemsOperation.h"
#import "VRInactiveTableView.h"
#import "VRMainWindowController.h"
#import "VRWorkspace.h"
#import "VRDefaultLogSetting.h"
#import "NSTableView+VR.H"


int qOpenQuicklyWindowWidth = 400;


@implementation VROpenQuicklyWindowController {
  __weak NSWindow *_targetWindow;
  __weak VRMainWindowController *_targetWindowController;
  __weak NSSearchField *_searchField;
  __weak VRInactiveTableView *_fileItemTableView;
  __weak NSProgressIndicator *_progressIndicator;
  __weak NSTextField *_itemCountTextField;
  __weak NSTextField *_workspaceTextField;
  NSOperationQueue *_filterOperationQueue;
  NSMutableArray *_filteredFileItems;
  NSOperationQueue *_uiUpdateOperationQueue;
}

@autowire(fileItemManager)
@autowire(notificationCenter)
@autowire(userDefaults);

#pragma mark Public
- (void)showForWindowController:(VRMainWindowController *)windowController {
  _targetWindowController = windowController;
  _targetWindow = windowController.window;

  CGRect contentRect = [_targetWindow contentRectForFrameRect:_targetWindow.frame];
  CGFloat xPos = NSMinX(contentRect) + NSWidth(contentRect) / 2 - qOpenQuicklyWindowWidth / 2
      - 2 * qOpenQuicklyWindowPadding;
  CGFloat yPos = NSMaxY(contentRect) - NSHeight(self.window.frame);

  self.window.frameOrigin = CGPointMake(xPos, yPos);

  [self.window makeKeyAndOrderFront:self];

  [self setupUiUpdateOperation];
}

- (void)cleanUp {
  @synchronized (self) {
    [_filterOperationQueue cancelAllOperations];
  }
}

- (IBAction)debug2Action:(id)sender {
  DDLogDebug(@"filter operations: %lu", _filterOperationQueue.operationCount);
}

#pragma mark NSObject

- (id)init {
  VROpenQuicklyWindow *win = [[VROpenQuicklyWindow alloc] initWithContentRect:
      CGRectMake(100, 100, qOpenQuicklyWindowWidth, 250)];

  self = [super initWithWindow:win];
  RETURN_NIL_WHEN_NOT_SELF

  _searchField = win.searchField;
  _searchField.delegate = self;

  _fileItemTableView = win.fileItemTableView;
  _fileItemTableView.dataSource = self;
  _fileItemTableView.delegate = self;
  _fileItemTableView.doubleAction = @selector(openSelectedFile:);

  _progressIndicator = win.progressIndicator;
  _itemCountTextField = win.itemCountTextField;
  _workspaceTextField = win.workspaceTextField;

  win.delegate = self;

  _filterOperationQueue = [[NSOperationQueue alloc] init];
  _filterOperationQueue.maxConcurrentOperationCount = 1;
  _filteredFileItems = [[NSMutableArray alloc] initWithCapacity:qMaximumNumberOfFilterResult];

  _uiUpdateOperationQueue = [[NSOperationQueue alloc] init];
  _uiUpdateOperationQueue.maxConcurrentOperationCount = 1;

  return self;
}

#pragma mark NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  if (!self.window.isVisible) {
    return 0;
  }

  if (_searchField.stringValue.length == 0) {
    return 0;
  }

  @synchronized (_filteredFileItems) {
    return _filteredFileItems.count;
  }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  @synchronized (_filteredFileItems) {
    VRScoredPath *scoredPath = _filteredFileItems[(NSUInteger) row];
    return scoredPath.displayName;
  }
}

#pragma mark NSTableViewDelegate
- (void)tableView:(NSTableView *)tableView willDisplayCell:(NSCell *)cell forTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)row {

  VRScoredPath *scoredPath = _filteredFileItems[(NSUInteger) row];
  cell.image = [_fileItemManager iconForUrl:scoredPath.url];
}

#pragma mark NSTextFieldDelegate
- (void)controlTextDidChange:(NSNotification *)obj {
  [self refilter];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
  NSLog(@"#################### %@", NSStringFromSelector(selector));
  if (selector == @selector(cancelOperation:)) {
    DDLogDebug(@"Open quickly cancelled");

    [self reset];
    return YES;
  }

  if (selector == @selector(insertNewline:)
      || selector == @selector(insertLineBreak:)
      || selector == @selector(insertNewlineIgnoringFieldEditor:)) {

    [self openSelectedFile:self];
    return YES;
  }

  // When we enter Cmd-CR, then we get noop: as the selector
  if (selector == @selector(noop:)) {
    NSEvent *event = [NSApp currentEvent];
    if ([event.charactersIgnoringModifiers characterAtIndex:0] == NSCarriageReturnCharacter
        && event.modifierFlags & NSCommandKeyMask) {

      [self openSelectedFile:self];
      return YES;
    }
  }

  if (selector == @selector(moveUp:)) {
    [_fileItemTableView moveSelectionByDelta:-1];
    return YES;
  }

  if (selector == @selector(moveDown:)) {
    [_fileItemTableView moveSelectionByDelta:1];
    return YES;
  }

  return NO;
}

#pragma mark NSWindowDelegate
- (void)windowDidResignMain:(NSNotification *)notification {
  DDLogDebug(@"Open quickly window resigned main");
  [self reset];
}

- (void)windowDidResignKey:(NSNotification *)notification {
  DDLogDebug(@"Open quickly window resigned key");
  [self reset];
}

#pragma mark TBInitializingBean
- (void)postConstruct {
  [_notificationCenter addObserver:self selector:@selector(chunkOfFileItemsAdded:)
                              name:qChunkOfNewFileItemsAddedEvent object:nil];
}

#pragma mark Private
- (void)chunkOfFileItemsAdded:(id)obj {
  [self refilter];
}

- (void)refilter {
  [_filterOperationQueue cancelAllOperations];

  [_filterOperationQueue addOperation:[[VRFilterItemsOperation alloc] initWithDict:@{
      qOperationFileItemManagerKey : _fileItemManager,
      qFilterItemsOperationFilteredItemsKey : _filteredFileItems,
      qFilterItemsOperationItemTableViewKey : _fileItemTableView,
      qFilterItemsOperationSearchStringKey : _searchField.stringValue,
  }]];
}

- (void)reset {
  [_filterOperationQueue cancelAllOperations];
  [_filteredFileItems removeAllObjects];

  [_fileItemManager resetTargetUrl];

  [self.window close];
  [(VROpenQuicklyWindow *) self.window reset];

  [_filteredFileItems removeAllObjects];
  [_fileItemTableView reloadData];
  [_progressIndicator stopAnimation:self];
  _itemCountTextField.stringValue = @"";

  [_targetWindow makeKeyAndOrderFront:self];
  _targetWindow = nil;
}

- (void)setupUiUpdateOperation {
  _progressIndicator.hidden = NO;
  _workspaceTextField.stringValue = _targetWindowController.workspace.workingDirectory.path;

  [_uiUpdateOperationQueue addOperationWithBlock:^{
    while (_targetWindow) {
      if (self.fileItemManager.fileItemOperationPending || _filterOperationQueue.operationCount > 0) {
        dispatch_to_main_thread(^{
          [_progressIndicator startAnimation:self];
        });
      } else {
        dispatch_to_main_thread(^{
          [_progressIndicator stopAnimation:self];
          _progressIndicator.hidden = YES;
        });
      }

      dispatch_to_main_thread(^{
        _itemCountTextField.stringValue = SF(@"%lu items", self.fileItemManager.urlsOfTargetUrl.count);
      });

      usleep(500);
    }
  }];
}

- (void)openSelectedFile:(id)sender {
  @synchronized (_filteredFileItems) {
    VRScoredPath *scoredPath = _filteredFileItems[(NSUInteger) _fileItemTableView.selectedRow];

    VROpenMode mode = open_mode_from_event(
        [NSApp currentEvent],
        [_userDefaults stringForKey:qDefaultDefaultOpeningBehavior]
    );

    [_targetWindowController openFileWithUrls:scoredPath.url openMode:mode];

    [self reset];
  }
}

@end
