/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Foundation/Foundation.h>


@interface VROpenQuicklyIgnorePattern : NSObject

- (instancetype)initWithPattern:(NSString *)pattern;
- (BOOL)matchesPath:(NSString *)absolutePath;

@end
