/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <CocoaLumberjack/DDLog.h>
#import "VRInvalidateCacheOperation.h"
#import "VRFileItemManager.h"
#import "VRFileItem.h"
#import "NSURL+VR.h"
#import "VRUtils.h"
#import "VRDefaultLogSetting.h"


NSString *const qInvalidatedCacheEvent = @"invalidated-cache-notification";
NSString *const qInvalidateCacheOperationParentItemsKey = @"parent-items";


static VRFileItem *find_file_item(NSURL *url, VRFileItem *parent) {
  if ([parent.url isEqual:url]) {
    return parent;
  }

  for (VRFileItem *child in parent.children) {
    if ([child.url isEqual:url]) {
      return child;
    }

    if (child.isDir && [child.url isParentToUrl:url]) {
      return find_file_item(url, child);
    }
  }

  return nil;
}


@implementation VRInvalidateCacheOperation {
  __weak VRFileItemManager *_fileItemManager;
  __weak NSNotificationCenter *_notificationCenter;

  NSArray *_parentItems;
  NSURL *_url;
}

#pragma mark Public
- (instancetype)initWithUrl:(NSURL *)url dict:(NSDictionary *)dict {

  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _fileItemManager = dict[qOperationFileItemManagerKey];
  _notificationCenter = dict[qOperationNotificationCenterKey];
  _parentItems = dict[qInvalidateCacheOperationParentItemsKey];

  _url = [url copy];

  return self;
}

#pragma mark NSOperation
- (void)main {
  @autoreleasepool {
    for (VRFileItem *parentItem in _parentItems) {
      VRFileItem *matchingItem = find_file_item(_url, parentItem);
      if (matchingItem) {
        DDLogDebug(@"Invalidating cache for %@ of the parent %@", matchingItem, parentItem.url);

        matchingItem.shouldCacheChildren = YES;

        dispatch_to_main_thread(^{
          [_notificationCenter postNotificationName:qInvalidatedCacheEvent object:matchingItem];
        });
      } else {
        DDLogDebug(@"%@ in %@ not yet cached, noop", _url, parentItem.url);
      }
    }
  }
}

@end
