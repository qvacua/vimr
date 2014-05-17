/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "VROperation.h"


extern NSString *const qInvalidatedCacheEvent;
extern NSString *const qInvalidateCacheOperationParentItemsKey;


@class VRFileItemManager;


@interface VRInvalidateCacheOperation : VROperation

- (instancetype)initWithUrl:(NSURL *)url dict:(NSDictionary *)dict;

@end
