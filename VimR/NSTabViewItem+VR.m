/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "NSTabViewItem+VR.h"
#import "VRDocument.h"
#import <objc/runtime.h>


static void const *qAssociatedDocumentTag = "qAssociatedDocument";


@implementation NSTabViewItem (VR)

- (VRDocument *)associatedDocument {
    return objc_getAssociatedObject(self, qAssociatedDocumentTag);
}

- (void)setAssociatedDocument:(VRDocument *)associatedDocument {
    objc_setAssociatedObject(self, qAssociatedDocumentTag, associatedDocument, OBJC_ASSOCIATION_ASSIGN);
}

@end
