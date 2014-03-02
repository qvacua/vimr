/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


extern NSString *const qMainWindowNibName;


@class VRMainWindowController;


@interface VRDocument : NSDocument

@property VRMainWindowController *mainWindowController;

- (void)makeWindowControllers;
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError;
- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError;

@end
