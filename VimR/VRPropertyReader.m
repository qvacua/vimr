/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRPropertyReader.h"
#import "NSString+TBCacao.h"
#import "VRDefaultLogSetting.h"


NSString *const qOpenQuicklyIgnorePatterns = @"open.quickly.ignore.patterns";
NSString *const qSelectNthTabActive = @"global.keybinding.select-nth-tab.active";
NSString *const qSelectNthTabModifier = @"global.keybinding.select-nth-tab.modifier";


static NSString *const qVimrRcFileName = @".vimr_rc";


@implementation VRPropertyReader

+ (NSDictionary *)properties {
  NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:qVimrRcFileName];
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    DDLogDebug(@"%@ not found", path);
    return @{};
  }

  NSError *error;
  NSString *content = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] encoding:NSUTF8StringEncoding error:&error];
  if (error) {
    DDLogWarn(@"There was an error opening %@: %@", path, error);
    return @{};
  }

  return [self read:content];
}

+ (NSDictionary *)read:(NSString *)input {
  NSMutableDictionary *result = [[NSMutableDictionary alloc] initWithCapacity:30];

  NSArray *lines = [input componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  for (NSString *line in lines) {
    if ([line startsWithString:@"#"]) {
      continue;
    }

    NSRange range = [line rangeOfString:@"="];
    if (range.location == NSNotFound) {
      continue;
    }

    NSUInteger indexOfValue = range.location + 1;
    if (line.length < indexOfValue) {
      continue;
    }

    NSCharacterSet *whiteSpaces = [NSCharacterSet whitespaceCharacterSet];
    NSString *key = [[line substringWithRange:NSMakeRange(0, range.location)] stringByTrimmingCharactersInSet:whiteSpaces];
    result[key] = [[line substringFromIndex:indexOfValue] stringByTrimmingCharactersInSet:whiteSpaces];
  }

  return result;
}

@end
