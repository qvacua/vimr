/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>

typedef NSMutableArray VRStack;
typedef NSMutableArray VRQueue;

/**
* Implements Stack and Queue using NSMutableArray
*/
@interface NSMutableArray (VR)

// Stack

/**
* Pushes the given object to the Stack (appends the object at the end of the array).
*/
- (void)push:(id)obj;

/**
* Pushes the given object n-times.
* 
* @param obj    the object to push
* @param times  how many times to push
*/
- (void)push:(id)obj times:(NSUInteger)times;

/**
* Pushes all elements of the given array to the Stack. The order of the elements of the given array is not altered, i.e.
* 
* array = [ a, b, c ] and stack = [ 3, 2, 1 ], then after [stack pushArray:array]
* stack = [c, b, a, 3, 2, 1 ], thus, pop gives you c
* 
* Internally this is done as follows
* array = [ a, b, c ] and stack (as NSArray) = [ 1, 2, 3 ], then after [stack pushArray:array]
* stack (as NSArray) = [ 1, 2, 3, a, b, c ]
* because pop gives you the last element of the stack as NSArray
* 
* @param array  the array from which the elements get inserted into the Stack
*/
- (void)pushArray:(NSArray *)array;

/**
* Pops the stack.
* Internally, pop gives you the last element of the NSMutableArray
*/
- (id)pop;

/**
* Tops the stack, i.e. it is the same as pop, but the returned element stays in the stack.
*/
- (id)top;


// Queue

/**
* Add the object to the Queue.
* Internally the object gets added as the first element of the NSMutableArray.
*/
- (void)enqueue:(id)object;

/**
* Add the object n-times to the Queue.
* 
* @param object the object to queue
* @param times  how many times to queue
*/
- (void)enqueue:(id)object times:(NSUInteger)times;

/**
* Add the elements of the given array to the Queue.
* array = [ a, b, c ] and queue = [ 1, 2, 3 ], then after [queue enqueueArray:array]
* queue = [ a, b, c, 1, 2, 3 ], thus dequeue gives you a
*/
- (void)enqueueArray:(NSArray *)array;

/**
* Dequeues the queue.
* Internally, dequeue gives you the first element of the NSMutableArray
*/
- (id)dequeue;

/**
* Peeks the queue, i.e. it is the same as dequeue, but the returned element stays in the queue
*/
- (id)peek;

@end
