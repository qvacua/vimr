/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "NSString+VR.h"


@implementation NSString (VR)

- (BOOL)hasString:(NSString *)str {
  return [self rangeOfString:str].location != NSNotFound;
}

@end
