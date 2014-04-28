/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@interface NSArray (VR)

- (BOOL)isEmpty;

/**
* We use NSRange in a non-standard way. Usually it is location + length, we use it as
* range.location = begin index
* range.length = end index
*/
- (NSArray *)indexesForChunkSize:(NSUInteger)size;

@end

