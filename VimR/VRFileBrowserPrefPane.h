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

extern NSString *const qOpenInNewTabDescription;
extern NSString *const qOpenInCurrentTabDescription;
extern NSString *const qOpenInVerticalSplitDescription;
extern NSString *const qOpenInHorizontalSplitDescription;

@interface VRFileBrowserPrefPane : VRPrefPane

#pragma mark Public
- (id)initWithUserDefaultsController:(NSUserDefaultsController *)userDefaultsController;

#pragma mark VRPrefPane
- (NSString *)displayName;

@end
