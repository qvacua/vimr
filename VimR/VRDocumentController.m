/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <MacVimFramework/MacVimFramework.h>
#import "VRDocumentController.h"


@implementation VRDocumentController

#pragma mark MMVimManagerDelegateProtocol
- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)controller {

}

- (void)manager:(MMVimManager *)manager vimControllerRemovedWithIdentifier:(unsigned int)identifier {

}

- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager {
    return [[NSMenuItem alloc] init]; // dummy menu item
}

@end
