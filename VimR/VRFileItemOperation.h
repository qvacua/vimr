/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


extern NSString *const qFileItemOperationOperationQueueKey;
extern NSString *const qFileItemOperationFileManagerKey;
extern NSString *const qFileItemOperationNotificationCenterKey;
extern NSString *const qFileItemOperationParentItemKey;
extern NSString *const qFileItemOperationRootUrlKey;
extern NSString *const qFileItemOperationFileItemsKey;


typedef enum {
  VRFileItemOperationTraverseMode = 0,
  VRFileItemOperationCacheMode,
} VRFileItemOperationMode;


@class VRFileItemManager;
@class VRFileItem;


@interface VRFileItemOperation : NSOperation

#pragma mark Public
- (BOOL)isPaused;
- (void)pause;
- (void)resume;

#pragma mark NSOperation
- (id)initWithMode:(VRFileItemOperationMode)mode dict:(NSDictionary *)dict;

@end
