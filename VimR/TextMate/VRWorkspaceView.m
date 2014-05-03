/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRWorkspaceView.h"
#import "VRTextMateUiUtils.h"


#ifndef SQ
#define SQ(x) ((x)*(x))
#endif


/**
* Copied and modified -Tae
*
* Frameworks/DocumentWindow/src/ProjectLayoutView.mm
* v2.0-alpha.9537
*/
@interface VRWorkspaceView ()

@property (nonatomic) NSView *fileBrowserDivider;
@property (nonatomic) NSLayoutConstraint *fileBrowserWidthConstraint;
@property (nonatomic) NSMutableArray *myConstraints;
@property (nonatomic) BOOL mouseDownRecursionGuard;

@end

@implementation VRWorkspaceView

- (id)initWithFrame:(NSRect)aRect {
  if (self = [super initWithFrame:aRect]) {
    _myConstraints = [NSMutableArray array];
    _fileBrowserWidth = 250;
    _increment = 1;
  }

  return self;
}

- (NSView *)replaceView:(NSView *)oldView withView:(NSView *)newView {
  if (newView == oldView)
    return oldView;

  [oldView removeFromSuperview];

  if (newView) {
    [newView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self addSubview:newView];
  }

  [self setNeedsUpdateConstraints:YES];
  return newView;
}

- (void)setDocumentView:(NSView *)aDocumentView {
  _documentView = [self replaceView:_documentView withView:aDocumentView];
}

- (void)setFileBrowserView:(NSView *)aFileBrowserView {
  _fileBrowserDivider = [self replaceView:_fileBrowserDivider withView:aFileBrowserView ? OakCreateVerticalLine([NSColor controlShadowColor], nil) : nil];
  _fileBrowserView = [self replaceView:_fileBrowserView withView:aFileBrowserView];
}

- (void)setFileBrowserOnRight:(BOOL)flag {
  if (_fileBrowserOnRight != flag) {
    _fileBrowserOnRight = flag;
    if (_fileBrowserView)
      [self setNeedsUpdateConstraints:YES];
  }
}

#ifndef CONSTRAINT
#define CONSTRAINT(str) [_myConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:str options:0 metrics:nil views:views]]
#endif

- (void)updateConstraints {
  [self removeConstraints:_myConstraints];
  [_myConstraints removeAllObjects];
  [super updateConstraints];

  NSDictionary *views = @{
      @"documentView" : _documentView,
      @"fileBrowserView" : _fileBrowserView ?: [NSNull null],
      @"fileBrowserDivider" : _fileBrowserDivider ?: [NSNull null],
  };

  // top & bottom
  CONSTRAINT(@"V:|[documentView]|");

  // left
  if (_fileBrowserView) {
    // width
    self.fileBrowserWidthConstraint = [NSLayoutConstraint constraintWithItem:_fileBrowserView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:_fileBrowserWidth];
    self.fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
    [_myConstraints addObject:self.fileBrowserWidthConstraint];

    CONSTRAINT(@"V:|[fileBrowserView]|");
    CONSTRAINT(@"V:|[fileBrowserDivider]|");

    if (_fileBrowserOnRight) {
      CONSTRAINT(@"H:|[documentView][fileBrowserDivider][fileBrowserView]|");
    } else {
      CONSTRAINT(@"H:|[fileBrowserView][fileBrowserDivider][documentView]|");
    }

  } else {
    CONSTRAINT(@"H:|[documentView]|");
  }

  [self addConstraints:_myConstraints];
  [[self window] invalidateCursorRectsForView:self];
}

#undef CONSTRAINT

- (NSRect)fileBrowserResizeRect {
  if (!_fileBrowserView)
    return NSZeroRect;
  NSRect r = _fileBrowserView.frame;
  return NSMakeRect(_fileBrowserOnRight ? NSMinX(r) - 3 : NSMaxX(r) - 4, NSMinY(r), 10, NSHeight(r));
}

- (void)resetCursorRects {
  [self addCursorRect:[self fileBrowserResizeRect] cursor:[NSCursor resizeLeftRightCursor]];
}

- (NSView *)hitTest:(NSPoint)aPoint {
  if (NSMouseInRect([self convertPoint:aPoint fromView:[self superview]], [self fileBrowserResizeRect], [self isFlipped]))
    return self;
  return [super hitTest:aPoint];
}

- (void)mouseDown:(NSEvent *)anEvent {
  if (_mouseDownRecursionGuard)
    return;
  _mouseDownRecursionGuard = YES;

  NSView *view = nil;
  NSPoint mouseDownPos = [self convertPoint:[anEvent locationInWindow] fromView:nil];
  if (NSMouseInRect(mouseDownPos, [self fileBrowserResizeRect], [self isFlipped]))
    view = _fileBrowserView;

  if (!view || [anEvent type] != NSLeftMouseDown) {
    [super mouseDown:anEvent];
  }
  else {
    if (_fileBrowserView) {
      self.fileBrowserWidthConstraint.constant = NSWidth(_fileBrowserView.frame);
      self.fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
    }

    NSEvent *mouseDownEvent = anEvent;
    NSRect initialFrame = view.frame;

    BOOL didDrag = NO;
    while ([anEvent type] != NSLeftMouseUp) {
      anEvent = [NSApp nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseDown | NSLeftMouseUpMask) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
      if ([anEvent type] != NSLeftMouseDragged)
        break;

      NSPoint mouseCurrentPos = [self convertPoint:[anEvent locationInWindow] fromView:nil];
      if (!didDrag && SQ(fabs(mouseDownPos.x - mouseCurrentPos.x)) + SQ(fabs(mouseDownPos.y - mouseCurrentPos.y)) < SQ(1))
        continue; // we didn't even drag a pixel

      if (view == _fileBrowserView) {
        CGFloat width = NSWidth(initialFrame) + (mouseCurrentPos.x - mouseDownPos.x) * (_fileBrowserOnRight ? -1 : +1);
        NSUInteger targetWidth = (NSUInteger) MAX(50, round(width));
        _fileBrowserWidth = targetWidth - targetWidth % _increment;

        self.fileBrowserWidthConstraint.constant = _fileBrowserWidth;
        self.fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow - 1;
      }

      [[self window] invalidateCursorRectsForView:self];
      didDrag = YES;
    }

    if (!didDrag) {
      NSView *view = [super hitTest:[[self superview] convertPoint:[mouseDownEvent locationInWindow] fromView:nil]];
      if (view && view != self) {
        [NSApp postEvent:anEvent atStart:NO];
        [view mouseDown:mouseDownEvent];
      }
    }

    self.fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
  }

  _mouseDownRecursionGuard = NO;
}

@end
