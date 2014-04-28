/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "NSArray+VR.h"


@implementation NSArray (VR)

- (BOOL)isEmpty {
  return self.count == 0;
}

- (NSArray *)indexesForChunkSize:(NSUInteger)size {
  @synchronized (self) {
    NSUInteger count = self.count;

    if (size == count) {
      return @[[NSValue valueWithRange:NSMakeRange(0, count - 1)]];
    }

    NSUInteger numberOfChunks = (NSUInteger) (floor(count / size) + 1);
    if (numberOfChunks == 1) {
      return @[[NSValue valueWithRange:NSMakeRange(0, count - 1)]];
    }

    NSMutableArray *indexes = [[NSMutableArray alloc] initWithCapacity:numberOfChunks];
    NSUInteger begin = 0;
    NSUInteger end = 0;
    for (NSUInteger i = 0; i < numberOfChunks; i++) {
      begin = i * size;
      if (i == numberOfChunks - 1) {
        end = count - 1;
      } else {
        end = size * (i + 1) - 1;
      }

      [indexes addObject:[NSValue valueWithRange:NSMakeRange(begin, end)]];
    }

    return indexes;
  }
}

@end
