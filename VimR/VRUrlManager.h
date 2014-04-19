/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@interface VRUrlManager : NSObject

@property (weak) NSFileManager *fileManager;

#pragma mark Public
- (void)start;
- (void)stop;

#pragma mark NSObject
- (id)init;

@end
