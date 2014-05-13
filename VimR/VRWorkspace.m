/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <MacVimFramework/MacVimFramework.h>
#import <TBCacao/TBCacao.h>
#import <CocoaLumberjack/DDLog.h>
#import "VRWorkspace.h"
#import "VRMainWindowController.h"
#import "VRFileItemManager.h"
#import "VRUtils.h"
#import "VRDefaultLogSetting.h"
#import "VRMainWindow.h"


static CGPoint qDefaultOrigin = {242, 364};


@interface VRWorkspace ()

@property (weak) MMVimController *vimController;
@property (readonly) NSMutableArray *openedBufferUrls;

@end

@implementation VRWorkspace

#pragma mark Public
- (void)openFileWithUrl:(NSURL *)url {
  [_mainWindowController openFileWithUrl:url];
}

- (BOOL)hasModifiedBuffer {
  return self.mainWindowController.vimController.hasModifiedBuffer;
}

- (void)setUpWithVimController:(MMVimController *)vimController {
  _vimController = vimController;

  CGPoint origin= [self cascadedWindowOrigin];
  VRMainWindowController *controller = [
      [VRMainWindowController alloc] initWithContentRect:CGRectMake(origin.x, origin.y, 480, 360)
  ];
  controller.workspace = self;

  controller.vimController = vimController;
  controller.vimView = vimController.vimView;

  vimController.delegate = (id <MMVimControllerDelegate>) controller;

  self.mainWindowController = controller;

  [controller showWindow:self];
}

- (void)setUpInitialBuffers {
  _openedBufferUrls = [self bufferUrlsFromVimBuffers:_vimController.buffers];
  DDLogDebug(@"opened buffers: %@", _openedBufferUrls);
}

- (void)updateBuffers {
  NSArray *vimBuffers = _vimController.buffers;
  NSMutableArray *bufferUrls = [self bufferUrlsFromVimBuffers:vimBuffers];
  if ([bufferUrls isEqualToArray:_openedBufferUrls]) {
    DDLogDebug(@"Buffers not changed, noop");
    return;
  }

  _openedBufferUrls = bufferUrls;
  NSURL *commonParent = common_parent_url(bufferUrls);
  if ([commonParent isEqualTo:_workingDirectory]) {
    DDLogDebug(@"Same workspace, noop");
    return;
  }

  [_fileItemManager unregisterUrl:_workingDirectory];
  _workingDirectory = commonParent;
  [_fileItemManager registerUrl:_workingDirectory];
  DDLogDebug(@"Registered new workspace: %@", _workingDirectory);
}

- (NSMutableArray *)bufferUrlsFromVimBuffers:(NSArray *)vimBuffers {
  NSMutableArray *bufferUrls = [[NSMutableArray alloc] initWithCapacity:vimBuffers.count];
  for (MMBuffer *buffer in vimBuffers) {
    if (buffer.fileName) {
      [bufferUrls addObject:[NSURL fileURLWithPath:buffer.fileName]];
    }
  }
  
  return bufferUrls;
}

- (void)cleanUpAndClose {
  [self.mainWindowController cleanUpAndClose];
  [self.fileItemManager unregisterUrl:self.workingDirectory];
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _openedBufferUrls = [[NSMutableArray alloc] initWithCapacity:10];

  return self;
}

- (CGPoint)cascadedWindowOrigin {
  CGPoint origin = qDefaultOrigin;

  NSWindow *curKeyWindow = [NSApp keyWindow];
  if ([curKeyWindow isKindOfClass:[VRMainWindow class]]) {
    origin = [curKeyWindow frame].origin;
    origin.x += 24;
    origin.y -= 48;

    CGSize curScreenSize = curKeyWindow.screen.visibleFrame.size;
    if (curScreenSize.width < origin.x + 500 || origin.y < 5) {
      origin = qDefaultOrigin;
    }
  }

  return origin;
}

@end
