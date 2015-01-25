/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Foundation/Foundation.h>


extern NSString *const qOpenQuicklyIgnorePatterns;
extern NSString *const qSelectNthTabActive;
extern NSString *const qSelectNthTabModifier;


@interface VRPropertyReader : NSObject

+ (NSDictionary *)read:(NSString *)input;
+ (NSDictionary *)properties;

@end
