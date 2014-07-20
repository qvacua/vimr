/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <VimRPluginDefinition/VRPlugin.h>
#import "VRDefaultLogSetting.h"
#import "VRPreviewWindowController.h"
#import "VRMainWindowController.h"
#import "VRUtils.h"
#import "VRPluginManager.h"
#import "VRInvalidateCacheOperation.h"
#import "VRFileItem.h"


@implementation VRPreviewWindowController {
  __weak VRMainWindowController *_mainWindowController;

  BOOL _windowHasBeenShown;

  NSView <VRPluginPreviewView> *_currentPreviewView;
  NSURL *_currentUrl;

  NSMutableArray *_previewViewConstraints;
}

#pragma mark Public
- (instancetype)initWithMainWindowController:(VRMainWindowController *)mainWindowController {
  self = [super initWithWindow:[self newPreviewWindow]];
  RETURN_NIL_WHEN_NOT_SELF

  _windowHasBeenShown = NO;
  _mainWindowController = mainWindowController;
  _previewViewConstraints = [[NSMutableArray alloc] init];

  return self;
}

- (void)setUp {
  [_notificationCenter addObserver:self selector:@selector(cacheInvalidated:) name:qInvalidatedCacheEvent object:nil];
}

- (void)previewForUrl:(NSURL *)url fileType:(NSString *)fileType {
  _currentUrl = url;

  _currentPreviewView = [_pluginManager previewViewForFileType:fileType];
  _currentPreviewView.translatesAutoresizingMaskIntoConstraints = NO;
  DDLogInfo(@"Using plugin %@ for %@", [_currentPreviewView class], fileType);

  if (!_windowHasBeenShown) {
    CGRect mainWinFrame = _mainWindowController.window.frame;
    CGPoint mainWinOrigin = mainWinFrame.origin;
    [self.window setFrameOrigin:CGPointMake(
        mainWinOrigin.x + 30,
        mainWinOrigin.y + mainWinFrame.size.height - 30 - self.window.frame.size.height
    )];
    _windowHasBeenShown = YES;
  }

  [self preparePreviewView:_currentPreviewView];
  [self showWindow:self];
  [_currentPreviewView previewFileAtUrl:url];

}

#pragma mark IBAction
- (IBAction)refreshPreview:(id)sender {
  DDLogInfo(@"Reloading preview of for %@", _currentUrl);
  [_currentPreviewView previewFileAtUrl:_currentUrl];
}

#pragma mark NSObject
- (void)dealloc {
  [_notificationCenter removeObserver:self];
}

#pragma mark Private
- (void)preparePreviewView:(NSView <VRPluginPreviewView> *)previewView {
  NSView *contentView = self.window.contentView;
  [contentView removeConstraints:_previewViewConstraints];
  contentView.subviews = @[];
  [contentView addSubview:previewView];

  NSDictionary *views = @{
      @"previewView" : previewView,
  };

  [_previewViewConstraints removeAllObjects];
  [_previewViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[previewView]|" options:0 metrics:nil views:views]];
  [_previewViewConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[previewView]|" options:0 metrics:nil views:views]];
  [contentView addConstraints:_previewViewConstraints];
}

- (NSWindow *)newPreviewWindow {
  NSWindow *window = [[NSWindow alloc] initWithContentRect:CGRectMake(100, 100, 640, 480)
                                                 styleMask:NSTitledWindowMask | NSUnifiedTitleAndToolbarWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
                                                   backing:NSBackingStoreBuffered defer:YES];
  window.hasShadow = YES;
  window.title = @"Preview";
  window.opaque = NO;
  window.releasedWhenClosed = NO;

  return window;
}

- (void)cacheInvalidated:(NSNotification *)notification {
  if (!self.window.isVisible) {
    return;
  }

  VRFileItem *fileItem = notification.object;
  if (![_currentUrl.URLByDeletingLastPathComponent isEqualTo:fileItem.url]) {
    return;
  }

  [self refreshPreview:self];
}

@end
