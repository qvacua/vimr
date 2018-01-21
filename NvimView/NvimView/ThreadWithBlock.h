/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

typedef void (^ThreadInitBlock)(id);

@interface ThreadWithBlock : NSThread

- (instancetype)initWithThreadInitBlock:(ThreadInitBlock)block;

@end