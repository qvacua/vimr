/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <XCTest/XCTest.h>


#define HC_SHORTHAND

#import <OCHamcrest/OCHamcrest.h>


#define MOCKITO_SHORTHAND

#import <OCMockito/OCMockito.h>

#import <objc/runtime.h>

#import <TBCacao/TBCacao.h>
#import "VRLog.h"


#define consistsOf(...) contains(__VA_ARGS__, nil)
#define consistsOfInAnyOrder(...) containsInAnyOrder(__VA_ARGS__, nil)

#define isYes is(@YES)
#define isNo is(@NO)


@interface VRBaseTestCase : XCTestCase

+ (TBContext *)mockContext;

- (TBContext *)context;
- (IMP)mockClassSelector:(SEL)targetSelector ofClass:(Class)targetClass
            withSelector:(SEL)mockSelector ofClass:(Class)mockClass;
- (void)restoreClassSelector:(SEL)targetSelector ofClass:(Class)targetClass withImpl:(IMP)originalImpl;

@end
