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

#pragma mark Public
- (id)initWithUserDefaultsController:(NSUserDefaultsController *)userDefaultsController;

#pragma mark VRPrefPane
- (NSString *)displayName;

@end
