/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>


@class VRAppDelegate;


@interface VROpenFilesCommand : NSScriptCommand

@property (readonly, nonatomic) NSApplication *app;
@property (readonly, nonatomic) VRAppDelegate *appDelegate;
@property (readonly, nonatomic) NSArray *fileUrls;

@end
