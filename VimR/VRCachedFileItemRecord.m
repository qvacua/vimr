/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRCachedFileItemRecord.h"
#import "VRFileItem.h"
#import "VRUtils.h"


@implementation VRCachedFileItemRecord

#pragma mark Public
- (instancetype)initWithFileItem:(VRFileItem *)fileItem {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _fileItem = fileItem;
  _countOfConsumer = 1;

  return self;
}

- (void)incrementConsumer {
  _countOfConsumer++;
}

- (void)decrementConsumer {
  _countOfConsumer--;
}

@end
