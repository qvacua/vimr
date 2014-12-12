/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VROpenFileInNewWindowCommand.h"
#import "VRDefaultLogSetting.h"
#import "VRAppDelegate.h"


@implementation VROpenFileInNewWindowCommand {

}

- (id)performDefaultImplementation {
  NSArray *args = [self argumentsAsString];

  DDLogDebug(@"calling open file in new window command with args: %@", args);
  [self.appDelegate application:self.app openFiles:args];

  return nil;
}

#pragma mark Private
- (NSArray *)argumentsAsString {
  NSArray *args = self.evaluatedArguments[@""];

  NSMutableArray *result = @[].mutableCopy;
  for (NSAppleEventDescriptor *descriptor in args) {
    [result addObject:descriptor.stringValue];
  }

  return result;
}

@end
