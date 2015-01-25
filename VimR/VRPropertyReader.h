/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Foundation/Foundation.h>


NSString *const qOpenQuicklyIgnorePatterns;


@interface VRPropertyReader : NSObject

+ (NSDictionary *)read:(NSString *)input;
+ (NSDictionary *)properties;

@end
