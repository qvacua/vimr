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


@interface VRDocument : NSDocument

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError;
- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError;

@end
