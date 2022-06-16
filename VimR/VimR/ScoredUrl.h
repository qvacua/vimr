/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@interface ScoredUrl : NSObject

@property (readonly, nonnull) NSURL *url;
@property (readonly) double score;

- (instancetype _Nonnull)initWithUrl:(NSURL * _Nonnull)url score:(double)score;
- (NSString * _Nonnull)description;
- (BOOL)isEqual:(id _Nullable)other;
- (BOOL)isEqualToUrl:(ScoredUrl * _Nullable)url;
- (NSUInteger)hash;

@end
