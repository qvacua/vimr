 /**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "VRCachedFileItemRecord.h"
#import "VRFileItem.h"


 @interface VRCachedFileItemRecordTest : VRBaseTestCase
@end

@implementation VRCachedFileItemRecordTest {
  VRFileItem *item;
  VRCachedFileItemRecord *record;
}

- (void)setUp {
  item = [[VRFileItem alloc] initWithUrl:[NSURL fileURLWithPath:@"/Users"]];
  record = [[VRCachedFileItemRecord alloc] initWithFileItem:item];
}

- (void)testCount {
  assertThat(@(record.countOfConsumer), is(@1));

  [record incrementConsumer];
  assertThat(@(record.countOfConsumer), is(@2));

  [record decrementConsumer];
  assertThat(@(record.countOfConsumer), is(@1));

  [record decrementConsumer];
  [record decrementConsumer];
  assertThat(@(record.countOfConsumer), is(@0));
}

- (void)testFileItem {
  assertThat(record.fileItem, is(item));
}


@end
