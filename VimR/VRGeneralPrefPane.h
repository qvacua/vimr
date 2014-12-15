/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>
#import "VRPrefPane.h"


@interface VRGeneralPrefPane : VRPrefPane

@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) NSWorkspace *workspace;
@property (nonatomic, weak) NSBundle *mainBundle;

#pragma mark Public
- (id)initWithUserDefaultsController:(NSUserDefaultsController *)userDefaultsController
                         fileManager:(NSFileManager *)fileManager
                           workspace:(NSWorkspace *)workspace
                          mainBundle:(NSBundle *)mainBundle;

#pragma mark VRPrefPane
- (NSString *)displayName;

@end
