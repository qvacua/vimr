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
#import "VRWorkspaceController.h"
#import "VRWorkspace.h"
#import "VRUtils.h"
#import "VRFileItemManager.h"
#import "VROpenQuicklyWindowController.h"


NSString *const qVimArgFileNamesToOpen = @"filenames";
NSString *const qVimArgOpenFilesLayout = @"layout";


@implementation VRWorkspaceController {
  NSMutableArray *_mutableWorkspaces;
  NSMutableDictionary *_pid2Workspace;
}

@autowire(fileItemManager)
@autowire(openQuicklyWindowController)
@autowire(vimManager)
@autowire(notificationCenter)
@autowire(userDefaults)

#pragma mark Properties
- (NSArray *)workspaces {
  return _mutableWorkspaces;
}

#pragma mark Public
- (void)selectBufferWithUrl:(NSURL *)url {
  for (VRWorkspace *workspace in _mutableWorkspaces) {
    if ([workspace.openedUrls containsObject:url]) {
      [workspace selectBufferWithUrl:url];

      return;
    }
  }
}

- (void)newWorkspace {
  [self createNewVimControllerWithWorkingDir:[[NSURL alloc] initFileURLWithPath:NSHomeDirectory()] args:nil];
}

- (void)openFilesInNewWorkspace:(NSArray *)fileUrls {
  NSDictionary *args = [self vimArgsFromFileUrls:fileUrls];
  NSURL *commonParentDir = common_parent_url(fileUrls);

  // for time being, always open a new window. Later we could offer "Open in Tab..." or similar
  [self createNewVimControllerWithWorkingDir:commonParentDir args:args];
}

- (void)cleanUp {
  [self.vimManager terminateAllVimProcesses];
}

- (BOOL)hasDirtyBuffers {
  for (VRWorkspace *workspace in _mutableWorkspaces) {
    if (workspace.hasModifiedBuffer) {
      return YES;
    }
  }

  return NO;
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _mutableWorkspaces = [[NSMutableArray alloc] initWithCapacity:5];
  _pid2Workspace = [[NSMutableDictionary alloc] initWithCapacity:5];

  return self;
}

#pragma mark MMVimManagerDelegateProtocol
- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)vimController {
  VRWorkspace *workspace = _pid2Workspace[@(vimController.pid)];

  [workspace setUpWithVimController:vimController];
}

- (void)manager:(MMVimManager *)manager vimControllerRemovedWithControllerId:(unsigned int)controllerId pid:(int)pid {
  VRWorkspace *workspace = _pid2Workspace[@(pid)];

  [_pid2Workspace removeObjectForKey:@(pid)];
  [_mutableWorkspaces removeObject:workspace];

  [workspace cleanUpAndClose];
}

- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager {
  return [[NSMenuItem alloc] init]; // dummy menu item
}

#pragma mark Private
- (NSDictionary *)vimArgsFromFileUrls:(NSArray *)fileUrls {
  NSMutableArray *filenames = [[NSMutableArray alloc] initWithCapacity:4];
  for (NSURL *url in fileUrls) {
    [filenames addObject:url.path];
  }

  return @{
      qVimArgFileNamesToOpen : filenames,
      qVimArgOpenFilesLayout : @(MMLayoutTabs),
  };
}

- (void)createNewVimControllerWithWorkingDir:(NSURL *)workingDir args:(id)args {
  int pid = [self.vimManager pidOfNewVimControllerWithArgs:args];
  VRWorkspace *workspace = [[VRWorkspace alloc] init];
  workspace.openQuicklyWindowController = _openQuicklyWindowController;
  workspace.fileItemManager = _fileItemManager;
  workspace.userDefaults = _userDefaults;
  workspace.notificationCenter = _notificationCenter;
  workspace.workspaceController = self;

  workspace.workingDirectory = workingDir;

  [self.fileItemManager registerUrl:workingDir];

  [_mutableWorkspaces addObject:workspace];
  _pid2Workspace[@(pid)] = workspace;
}

@end
