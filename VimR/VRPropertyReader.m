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


@implementation VRPropertyReader

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
