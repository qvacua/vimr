/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@interface FuzzyMatcher : NSObject

@property (readonly) NSInteger maxPatternLength;
@property (readonly) NSInteger maxTextLength;
@property (readonly) NSInteger minScore;

- (instancetype _Nonnull)initWithPattern:(NSString * _Nonnull)pattern;
- (NSInteger)score:(NSString * _Nonnull)text;

@end
