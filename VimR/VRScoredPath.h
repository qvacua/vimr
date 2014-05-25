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
@property NSURL *url;
@property NSString *displayName;
@property NSImage *icon;

#pragma mark Public
- (instancetype)initWithUrl:(NSURL *)url;
- (void)computeScoreForCandidate:(NSString *)candidate;

#pragma mark NSObject
- (NSString *)description;

@end
