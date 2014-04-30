/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/DDLog.h>


@interface VRLogFormatter : NSObject <DDLogFormatter>

- (id)init;
- (NSString *)formatLogMessage:(DDLogMessage *)msg;

@end
