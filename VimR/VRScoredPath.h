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
@property NSString *displayName;

#pragma mark Public
- (instancetype)initWithPath:(NSString *)path;
- (void)computeScoreForCandidate:(NSString *)candidate;

#pragma mark NSObject
- (NSString *)description;

@end
