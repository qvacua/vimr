/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import <TBCacao/TBCacao.h>


@interface VRDocumentController : NSDocumentController <TBBean, MMVimManagerDelegateProtocol>

- (id)init;

- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)controller;
- (void)manager:(MMVimManager *)manager vimControllerRemovedWithIdentifier:(unsigned int)identifier;
- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager;

@end
