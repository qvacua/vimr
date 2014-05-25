#import <Cocoa/Cocoa.h>

/**
* Frameworks/OakAppKit/src/NSimage Addtions.mm
* v2.0-alpha.9537
*/
@interface NSImage (ImageFromBundle)

+ (NSImage *)imageNamed:(NSString *)aName inSameBundleAsClass:(id)anObject;

- (void)drawAdjustedAtPoint:(NSPoint)aPoint fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op
                   fraction:(CGFloat)delta;
- (void)drawAdjustedInRect:(NSRect)dstRect fromRect:(NSRect)srcRect operation:(NSCompositingOperation)op
                  fraction:(CGFloat)delta;

@end
