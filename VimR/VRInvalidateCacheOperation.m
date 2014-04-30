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


static const int ddLogLevel = LOG_LEVEL_DEBUG;


@implementation VRInvalidateCacheOperation {
  __weak VRFileItemManager *_fileItemManager;
  NSArray *_parentItems;
  NSURL *_url;
}

- (instancetype)initWithUrl:(NSURL *)url parentItems:(NSArray *)parentItems
            fileItemManager:(__weak VRFileItemManager *)fileItemManager {

  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _fileItemManager = fileItemManager;
  _parentItems = parentItems;
  _url = [url copy];

  return self;
}

- (void)main {
  @autoreleasepool {
    for (VRFileItem *parentItem in _parentItems) {
      VRFileItem *matchingItem = [self findFileItemForUrl:_url inParent:parentItem];
      if (matchingItem) {
        DDLogDebug(@"Invalidating cache for %@ of the parent %@", matchingItem, parentItem.url);

        matchingItem.shouldCacheChildren = YES;
      } else {
        DDLogDebug(@"%@ in %@ not yet cached, noop", _url, parentItem.url);
      }
    }
  }
}

- (VRFileItem *)findFileItemForUrl:(NSURL *)url inParent:(VRFileItem *)parent {
  if ([parent.url isEqual:url]) {
    return parent;
  }

  for (VRFileItem *child in parent.children) {
    if ([child.url isEqual:url]) {
      return child;
    }

    if (child.isDir && [child.url isParentToUrl:url]) {
      return [self findFileItemForUrl:url inParent:child];
    }
  }

  return nil;
}

@end
