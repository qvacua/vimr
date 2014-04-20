/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "NSMutableArray+VR.h"

@implementation NSMutableArray (VR)

- (void)push:(id)inObject {
    if (inObject != nil) {
        [self addObject:inObject];
    }
}

- (void)push:(id)obj times:(NSUInteger)times {
    for (NSUInteger i = 0; i < times; i++) {
        [self push:obj];
    }
}

- (void)pushArray:(NSArray *)array {
    if (array != nil) {
        [self addObjectsFromArray:array];
    }
}

- (id)pop {
    id theResult = nil;
    
    if([self count] != 0) {
        theResult = [self lastObject];
        [self removeLastObject];
    }
    
    return theResult;
}

- (id)top {
    if ([self count] > 0) {
        return [self lastObject];
    }

    return nil;
}

- (void)enqueue:(id)object {
    if (object != nil) {
        [self insertObject:object atIndex:0];
    }
}

- (void)enqueue:(id)object times:(NSUInteger)times {
    for (NSUInteger i = 0; i < times; i++) {
        [self enqueue:object];
    }
}

- (void)enqueueArray:(NSArray *)array {
    if (array != nil && [array count] > 0) {
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [array count])];
        [self insertObjects:array atIndexes:indexes];
    }
}

- (id)dequeue {
    id result = nil;

    if ([self count] > 0) {
        result = [self objectAtIndex:0];;
        [self removeObjectAtIndex:0];
    }

    return result;
}

- (id)peek {
    if ([self count] > 0) {
        return [self objectAtIndex:0];
    }

    return nil;
}

@end
