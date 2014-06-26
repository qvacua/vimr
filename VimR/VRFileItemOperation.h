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
extern NSString *const qFileItemOperationUrlsForTargetUrlKey;
extern NSString *const qFileItemOperationPauseConditionKey;


typedef enum {
  VRFileItemOperationTraverseMode = 0,
  VRFileItemOperationShallowCacheMode,
} VRFileItemOperationMode;


@class VRFileItemManager;
@class VRFileItem;


@interface VRFileItemOperation : VROperation

#pragma mark Public
- (void)pause;
- (void)resume;
- (id)initWithMode:(VRFileItemOperationMode)mode dict:(NSDictionary *)dict;

#pragma mark NSObject
+ (void)initialize;

@end
