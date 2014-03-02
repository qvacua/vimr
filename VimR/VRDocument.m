/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRDocument.h"
#import "VRMainWindowController.h"


NSString *const qMainWindowNibName = @"MainWindow";


@implementation VRDocument

#pragma mark NSDocument
- (void)makeWindowControllers {
    _mainWindowController = [[VRMainWindowController alloc] initWithWindowNibName:qMainWindowNibName];
    [self addWindowController:_mainWindowController];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    return NO;
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
    return NO;
}

@end
