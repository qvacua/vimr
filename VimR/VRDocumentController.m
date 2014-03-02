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


@interface VRDocumentController ()

@property MMVimManager *vimManager;

@end

@implementation VRDocumentController

#pragma mark NSDocumentController
- (id)init {
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _vimManager = [[MMVimManager alloc] init];
    _vimManager.delegate = self;
    [_vimManager setUp];

    return self;
}

#pragma mark MMVimManagerDelegateProtocol
- (void)manager:(MMVimManager *)manager vimControllerCreated:(MMVimController *)controller {

}

- (void)manager:(MMVimManager *)manager vimControllerRemovedWithIdentifier:(unsigned int)identifier {

}

- (NSMenuItem *)menuItemTemplateForManager:(MMVimManager *)manager {
    return [[NSMenuItem alloc] init]; // dummy menu item
}

@end
