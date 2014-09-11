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

- (BOOL)contains:(NSString *)str {
  return [str rangeOfString:str].location != NSNotFound;
}

@end
