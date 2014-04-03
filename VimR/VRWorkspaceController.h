/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <MacVimFramework/MacVimFramework.h>

extern NSString *const qMainWindowNibName;

@class VRMainWindowController;

extern NSString *const qVimArgFileNamesToOpen;
extern NSString *const qVimArgOpenFilesLayout;

@interface VRWorkspaceController : NSObject <MMVimManagerDelegateProtocol>

#pragma mark Properties
@property (weak) MMVimManager *vimManager;

#pragma mark Public
@property VRMainWindowController *mainWindowController;
- (void)newWorkspace;
- (void)openFiles:(NSArray *)fileUrls;
- (void)cleanup;

#pragma mark MMVimManagerDelegate
- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)controller;
- (void)manager:(MMVimManager *)manager vimControllerRemovedWithControllerId:(unsigned int)controllerId pid:(int)pid;
- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager;

@end
