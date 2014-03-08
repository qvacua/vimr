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


@class VRDocument;
@class VRMainWindowController;

extern NSString *const qMainWindowNibName;
extern NSString *const qVimArgFileNamesToOpen;

@interface VRDocumentController : NSDocumentController <MMVimManagerDelegateProtocol>

@property (weak) MMVimManager *vimManager;

- (VRMainWindowController *)mainWindowControllerForDocument:(VRDocument *)doc;

- (id)init;
- (void)dealloc;

- (IBAction)newTab:(id)sender;
- (IBAction)newDocument:(id)sender;
- (IBAction)openDocument:(id)sender;

- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)controller;
- (void)manager:(MMVimManager *)manager vimControllerRemovedWithControllerId:(unsigned int)vimControllerId pid:(int)pid;
- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager;

@end
