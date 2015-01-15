/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRBaseTestCase.h"
#import "VRPropertyReader.h"


@interface VRPropertyReaderTest : VRBaseTestCase
@end


@implementation VRPropertyReaderTest

- (void)testRead {
  VRPropertyReader *reader = [[VRPropertyReader alloc] init];

  // @formatter:off
  NSDictionary *properties = [reader read:
      @"\n\n"
       "# first=comment\n"
       "#second\n"
       "a = 1\n"
       "b= 2\n"
       "# third\n"
       "c=3 \n"
       "d=\n"
       "e 4\n"
       "open.quickly.patterns = */.git/*, .gitignore\n\n\n"
       "# last\n\n"
  ];
  // @formatter:on

  assertThat(properties.allKeys, hasCountOf(5));
  assertThat(properties[@"a"], is(@"1"));
  assertThat(properties[@"b"], is(@"2"));
  assertThat(properties[@"c"], is(@"3"));
  assertThat(properties[@"d"], is(@""));
  assertThat(properties[@"open.quickly.patterns"], is(@"*/.git/*, .gitignore"));

}

@end
