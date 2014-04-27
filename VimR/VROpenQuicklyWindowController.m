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


int qOpenQuicklyWindowWidth = 400;


#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_DEBUG;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif


@interface VROpenQuicklyWindowController ()

@property (weak) NSWindow *targetWindow;
@property (weak) NSSearchField *searchField;
@property (weak) NSTableView *fileItemTableView;
@property (weak) NSProgressIndicator *progressIndicator;
@property (readonly) NSOperationQueue *operationQueue;
@property (readonly) NSMutableArray *filteredFileItems;
@property (readonly) NSOperationQueue *progressOperationQueue;

@end

@implementation VROpenQuicklyWindowController

TB_AUTOWIRE(fileItemManager)

TB_AUTOWIRE(notificationCenter)

#pragma mark Public
- (void)showForWindow:(NSWindow *)targetWindow {
  self.targetWindow = targetWindow;

  CGRect contentRect = [targetWindow contentRectForFrameRect:targetWindow.frame];
  CGFloat xPos = NSMinX(contentRect) + NSWidth(contentRect) / 2 - qOpenQuicklyWindowWidth / 2
      - 2 * qOpenQuicklyWindowPadding;
  CGFloat yPos = NSMaxY(contentRect) - NSHeight(self.window.frame);

  self.window.frameOrigin = CGPointMake(xPos, yPos);

  [self.window makeKeyAndOrderFront:self];

  _progressIndicator.hidden = NO;
  [_progressOperationQueue addOperationWithBlock:^{
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
      usleep(500);
    }
  }];
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

  win.delegate = self;

  _operationQueue = [[NSOperationQueue alloc] init];
  _operationQueue.maxConcurrentOperationCount = 1;
  _filteredFileItems = [[NSMutableArray alloc] initWithCapacity:qMaximumNumberOfFilterResult];

  _progressOperationQueue = [[NSOperationQueue alloc] init];
  _progressOperationQueue.maxConcurrentOperationCount = 1;

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
    return scoredPath.path;
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
    DDLogDebug(@"Open quickly window: Enter pressed");
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

  [_targetWindow makeKeyAndOrderFront:self];
  _targetWindow = nil;
}

@end
