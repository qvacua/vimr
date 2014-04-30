/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@class VRFileItemManager;


@interface VRInvalidateCacheOperation : NSOperation

- (instancetype)initWithUrl:(NSURL *)url parentItems:(NSArray *)parentItems
            fileItemManager:(__weak VRFileItemManager *)fileItemManager;

@end
