/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


extern NSString *const qUrlGetResourceValueIsDirException;
extern NSString *const qUrlNoParentException;


@interface NSURL (VR)

- (BOOL)isDirectory;

- (NSString *)parentName;
@end
