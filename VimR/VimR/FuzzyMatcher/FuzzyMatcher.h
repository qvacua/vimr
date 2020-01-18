/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@interface FuzzyMatcher : NSObject

+ (NSInteger)maxPatternLength;
+ (NSInteger)maxTextLength;
+ (NSInteger)minScore;

- (instancetype _Nonnull)initWithPattern:(NSString * _Nonnull)pattern;
- (NSInteger)score:(NSString * _Nonnull)text;

@end
