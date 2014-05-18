/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


extern NSString *const qUrlGetResourceValueIsDirExceptionName;
extern NSString *const qUrlNoParentExceptionName;


@interface NSURL (VR)

- (BOOL)isHidden;
- (BOOL)isDirectory;

- (NSString *)parentName;

- (BOOL)isParentToUrl:(NSURL *)url;

@end
