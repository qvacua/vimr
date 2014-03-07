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


extern NSString *const qMainWindowNibName;


@class VRMainWindowController;
@class VRDocumentController;


@interface VRDocument : NSDocument

@property (weak) VRDocumentController *documentController;
@property (weak) VRMainWindowController *mainWindowController;

- (void)makeWindowControllers;
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError;
- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError;

@end
