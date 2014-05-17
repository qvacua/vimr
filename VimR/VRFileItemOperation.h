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


extern NSString *const qFileItemOperationOperationQueueKey;
extern NSString *const qFileItemOperationParentItemKey;
extern NSString *const qFileItemOperationRootUrlKey;
extern NSString *const qFileItemOperationFileItemsKey;


typedef enum {
  VRFileItemOperationTraverseMode = 0,
  VRFileItemOperationCacheMode,
  VRFileItemOperationShallowCacheMode,
} VRFileItemOperationMode;


@class VRFileItemManager;
@class VRFileItem;


@interface VRFileItemOperation : VROperation

#pragma mark NSOperation
- (id)initWithMode:(VRFileItemOperationMode)mode dict:(NSDictionary *)dict;

@end
