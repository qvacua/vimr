/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBContext.h>
#import "VRBaseTestCase.h"


@implementation VRBaseTestCase {
    IMP contextOriginalImpl;
}

- (void)setUp {
    contextOriginalImpl = [self mockClassSelector:@selector(sharedContext) ofClass:[TBContext class]
                                     withSelector:@selector(mockContext) ofClass:[self class]];
}

- (void)tearDown {
    [self restoreClassSelector:@selector(sharedContext) ofClass:[TBContext class] withImpl:contextOriginalImpl];
}

+ (TBContext *)mockContext {
    static TBContext *context = nil;
    if (context == nil) {
        context = mock([TBContext class]);
    }

    return context;
}

- (TBContext *)context {
    return [[self class] mockContext];
}

- (IMP)mockClassSelector:(SEL)targetSelector ofClass:(Class)targetClass
            withSelector:(SEL)mockSelector ofClass:(Class)mockClass {

    Method mockMethod = class_getClassMethod(mockClass, mockSelector);
    IMP mockImpl = method_getImplementation(mockMethod);
    Method originalMethod = class_getClassMethod(targetClass, targetSelector);
    IMP originalImpl = method_setImplementation(originalMethod, mockImpl);

    return originalImpl;
}

- (void)restoreClassSelector:(SEL)targetSelector ofClass:(Class)targetClass withImpl:(IMP)originalImpl {
    Method originalMethod = class_getClassMethod(targetClass, targetSelector);
    method_setImplementation(originalMethod, originalImpl);
}

@end
