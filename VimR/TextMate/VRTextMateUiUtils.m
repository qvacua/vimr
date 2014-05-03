/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRTextMateUiUtils.h"


/**
* Frameworks/OakAppKit/src/OakUIConstructionFunctions.mm
* v2.0-alpha.9537
*/

OakDividerLineView *OakCreateDividerLineWithColor(NSColor *color, NSColor *secondaryColor) {
  OakDividerLineView *box = [[OakDividerLineView alloc] initWithFrame:NSZeroRect];
  box.translatesAutoresizingMaskIntoConstraints = NO;
  box.boxType = NSBoxCustom;
  box.borderType = NSLineBorder;
  box.borderColor = color;
  box.primaryColor = color;
  box.secondaryColor = secondaryColor;
  box.usePrimaryColor = YES;
  return box;
}

NSBox *OakCreateVerticalLine(NSColor *primaryColor, NSColor *secondaryColor) {
  OakDividerLineView *res = OakCreateDividerLineWithColor(primaryColor, secondaryColor);
  res.intrinsicContentSize = NSMakeSize(1, NSViewNoInstrinsicMetric);
  [res setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
  return res;
}


@implementation OakDividerLineView

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
  if (!self.secondaryColor)
    return;

  if (self.window) {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:self.window];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:self.window];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:self.window];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:self.window];
  }

  if (newWindow) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeMainOrKey:) name:NSWindowDidBecomeMainNotification object:newWindow];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeMainOrKey:) name:NSWindowDidResignMainNotification object:newWindow];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeMainOrKey:) name:NSWindowDidBecomeKeyNotification object:newWindow];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidChangeMainOrKey:) name:NSWindowDidResignKeyNotification object:newWindow];
  }

  self.usePrimaryColor = ([newWindow styleMask] & NSFullScreenWindowMask) || [newWindow isMainWindow] || [newWindow isKeyWindow];
}

- (void)windowDidChangeMainOrKey:(NSNotification *)aNotification {
  self.usePrimaryColor = ([self.window styleMask] & NSFullScreenWindowMask) || [self.window isMainWindow] || [self.window isKeyWindow];
}

- (void)setUsePrimaryColor:(BOOL)flag {
  if (_usePrimaryColor != flag) {
    _usePrimaryColor = flag;
    self.borderColor = flag ? self.primaryColor : self.secondaryColor;
  }
}

- (BOOL)isOpaque {
  return YES;
}

@end
