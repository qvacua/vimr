/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>
#import "VROpenFileCommand.h"


@interface VROpenFileInFrontmostWindowCommand : VROpenFileCommand

#pragma mark NSScriptCommand
- (id)performDefaultImplementation;

@end
