#import <Cocoa/Cocoa.h>
#import <oak/misc.h>


enum {
  OakImageAndTextCellHitImage = (1 << 10),
  OakImageAndTextCellHitText = (1 << 11),
};

/**
* Frameworks/OakAppKit/src/NSimage Addtions.mm
* v2.0-alpha.9537
*/
@interface OakImageAndTextCell : NSTextFieldCell

- (NSRect)imageFrameWithFrame:(NSRect)aRect inControlView:(NSView *)aView;
- (NSRect)textFrameWithFrame:(NSRect)aRect inControlView:(NSView *)aView;

@end
