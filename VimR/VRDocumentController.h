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

@interface VRDocumentController : NSDocumentController <MMVimManagerDelegateProtocol>

@property (weak) MMVimManager *vimManager;

- (void)requestVimControllerForDocument:(VRDocument *)doc;

- (id)init;
- (void)dealloc;

- (void)addDocument:(NSDocument *)document;

- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)controller;
- (void)manager:(MMVimManager *)manager vimControllerRemovedWithControllerId:(unsigned int)vimControllerId pid:(int)pid;
- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager;

@end
