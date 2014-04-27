/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@interface VRScoredPath : NSObject

@property double score;
@property NSString *path;
@property (readonly) NSString *displayName;

- (instancetype)initWithPath:(NSString *)path;
- (void)computeScoreForCandidate:(NSString *)candidate;
- (NSString *)description;

@end
