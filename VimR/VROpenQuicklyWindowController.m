/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBCacao.h>
#import <CocoaLumberjack/DDLog.h>
#import "VROpenQuicklyWindowController.h"
#import "VROpenQuicklyWindow.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"
#import "VRScoredPath.h"
#import "VRFilterItemsOperation.h"
#import "VRInactiveTableView.h"
#import "VRMainWindowController.h"
#import "VRWorkspace.h"


int qOpenQuicklyWindowWidth = 400;


#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_DEBUG;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface VROpenQuicklyWindowController ()

@property (weak) NSWindow *targetWindow;
@property (weak) VRMainWindowController *targetWindowController;
@property (weak) NSSearchField *searchField;
@property (weak) VRInactiveTableView *fileItemTableView;
@property (weak) NSProgressIndicator *progressIndicator;
@property (weak) NSTextField *itemCountTextField;
@property (readonly) NSOperationQueue *operationQueue;
@property (readonly) NSMutableArray *filteredFileItems;
@property (readonly) NSOperationQueue *uiUpdateOperationQueue;

@end

@implementation VROpenQuicklyWindowController

TB_AUTOWIRE(fileItemManager)
TB_AUTOWIRE(notificationCenter)

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
    [_operationQueue cancelAllOperations];
  }
}

- (IBAction)secondDebugAction:(id)sender {
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

  _progressIndicator = win.progressIndicator;
  _itemCountTextField = win.itemCountTextField;

  win.delegate = self;

  _operationQueue = [[NSOperationQueue alloc] init];
  _operationQueue.maxConcurrentOperationCount = 1;
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

#pragma mark NSTextFieldDelegate
- (void)controlTextDidChange:(NSNotification *)obj {
  [self refilter];
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)selector {
  if (selector == @selector(cancelOperation:)) {
    DDLogDebug(@"Open quickly cancelled");

    [self reset];
    return YES;
  }

  if (selector == @selector(insertNewline:)) {
    @synchronized (_filteredFileItems) {
      VRScoredPath *scoredPath = _filteredFileItems[(NSUInteger) _fileItemTableView.selectedRow];
      [_targetWindowController.workspace openFileWithUrl:[NSURL fileURLWithPath:scoredPath.path]];
      [self reset];
      return YES;
    }
  }

  if (selector == @selector(moveUp:)) {
    [self moveSelectionByDelta:-1];
    return YES;
  }

  if (selector == @selector(moveDown:)) {
    [self moveSelectionByDelta:1];
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
  [_operationQueue cancelAllOperations];

  [_operationQueue addOperation:[[VRFilterItemsOperation alloc] initWithDict:@{
      qFilterItemsOperationFileItemManagerKey : self.fileItemManager,
      qFilterItemsOperationFilteredItemsKey : self.filteredFileItems,
      qFilterItemsOperationItemTableViewKey : self.fileItemTableView,
      qFilterItemsOperationSearchStringKey : self.searchField.stringValue,
  }]];
}

- (void)reset {
  [_operationQueue cancelAllOperations];
  [_filteredFileItems removeAllObjects];

  [_fileItemManager resetTargetUrl];

  [self.window close];
  [(VROpenQuicklyWindow *) self.window reset];

  [_filteredFileItems removeAllObjects];
  [_fileItemTableView reloadData];
  [_progressIndicator stopAnimation:self];
  self.itemCountTextField.stringValue = @"";

  [_targetWindow makeKeyAndOrderFront:self];
  _targetWindow = nil;
}

- (void)setupUiUpdateOperation {
  _progressIndicator.hidden = NO;

  [_uiUpdateOperationQueue addOperationWithBlock:^{
    while (self.targetWindow) {
      if (self.fileItemManager.isBusy || self.operationQueue.operationCount > 0) {
        dispatch_to_main_thread(^{
          [self.progressIndicator startAnimation:self];
        });
      } else {
        dispatch_to_main_thread(^{
          [self.progressIndicator stopAnimation:self];
          self.progressIndicator.hidden = YES;
        });
      }

      dispatch_to_main_thread(^{
        self.itemCountTextField.stringValue = SF(@"%lu items", self.fileItemManager.fileItemsOfTargetUrl.count);
      });

      usleep(500);
    }
  }];
}

- (void)moveSelectionByDelta:(NSInteger)delta {
  NSInteger selectedRow = _fileItemTableView.selectedRow;
  NSUInteger lastIndex = (NSUInteger) [self numberOfRowsInTableView:_fileItemTableView] - 1;
  NSUInteger targetIndex;

  if (selectedRow + delta < 0) {
    targetIndex = lastIndex;
  } else if (selectedRow + delta > lastIndex) {
    targetIndex = 0;
  } else {
    targetIndex = (NSUInteger) (selectedRow + delta);
  }

  [_fileItemTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:targetIndex] byExtendingSelection:NO];
  [_fileItemTableView scrollRowToVisible:targetIndex];
}

@end
