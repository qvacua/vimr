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


@class VRMainWindowController;

@interface VRDocument : NSDocument

#pragma mark Properties
@property BOOL dirty;
@property (readonly) BOOL transient;
@property (weak) VRMainWindowController *mainWindowController;

#pragma mark NSDocument
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError;
- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError;

@end
