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

- (instancetype)initWithPath:(NSString *)path score:(double)score;
- (NSString *)description;

@end
