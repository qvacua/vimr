/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <MacVimFramework/MacVimFramework.h>
#import "VRWorkspaceView.h"
#import "VRTextMateUiUtils.h"
#import "VRFileBrowserView.h"


#define SQ(x) ((x)*(x))
#define CONSTRAINT(str) [_myConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:str options:0 metrics:nil views:views]]


/**
* Copied and modified from TextMate -Tae
*
* Frameworks/DocumentWindow/src/ProjectLayoutView.mm
* v2.0-alpha.9537
*/
@interface VRWorkspaceView ()

@property NSView *fileBrowserDivider;
@property NSLayoutConstraint *fileBrowserWidthConstraint;
@property NSLayoutConstraint *vimViewWidthConstraint;
@property NSLayoutConstraint *vimViewHeightConstraint;
@property NSMutableArray *myConstraints;
@property BOOL mouseDownRecursionGuard;
@property CGFloat fileBrowserWidth;
@property NSUInteger dragIncrement;

@end

@implementation VRWorkspaceView {
  MMVimView *_vimView;
  VRFileBrowserView *_fileBrowserView;
  BOOL _fileBrowserOnRight;
}

#pragma mark Properties
- (MMVimView *)vimView {
  @synchronized (self) {
    return _vimView;
  }
}

- (void)setVimView:(MMVimView *)aVimView {
  @synchronized (self) {
    _vimView = [self replaceView:_vimView withView:aVimView];
    _dragIncrement = (NSUInteger) _vimView.textView.cellSize.width;
  }
}

- (VRFileBrowserView *)fileBrowserView {
  @synchronized (self) {
    return _fileBrowserView;
  }
}

- (void)setFileBrowserView:(VRFileBrowserView *)aFileBrowserView {
  @synchronized (self) {
    NSBox *dividerView = aFileBrowserView ? OakCreateVerticalLine([NSColor controlShadowColor], nil) : nil;

    _fileBrowserDivider = [self replaceView:_fileBrowserDivider withView:dividerView];
    _fileBrowserView = [self replaceView:_fileBrowserView withView:aFileBrowserView];
  }
}

- (BOOL)fileBrowserOnRight {
  @synchronized (self) {
    return _fileBrowserOnRight;
  }
}

- (void)setFileBrowserOnRight:(BOOL)flag {
  @synchronized (self) {
    if (_fileBrowserOnRight != flag) {
      _fileBrowserOnRight = flag;

      if (_fileBrowserView) {
        self.needsUpdateConstraints = YES;
      }
    }
  }
}

#pragma mark NSView
- (id)initWithFrame:(NSRect)aRect {
  if (self = [super initWithFrame:aRect]) {
    _myConstraints = [NSMutableArray array];
    _fileBrowserWidth = 250;
    _dragIncrement = 1;
  }

  return self;
}

- (void)updateConstraints {
  [self removeConstraints:_myConstraints];
  [_myConstraints removeAllObjects];
  [super updateConstraints];

  NSDictionary *views = @{
      @"documentView" : _vimView,
      @"fileBrowserView" : _fileBrowserView ?: [NSNull null],
      @"fileBrowserDivider" : _fileBrowserDivider ?: [NSNull null],
  };

  CONSTRAINT(@"V:|[documentView]|");
  [self addVimViewMinSizeConstraints];

  if (_fileBrowserView) {
    [self addFileBrowserWidthConstraint];

    CONSTRAINT(@"V:|[fileBrowserView(>=100)]|");
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
  [self.window invalidateCursorRectsForView:self];
}

- (void)addFileBrowserWidthConstraint {
  _fileBrowserWidthConstraint = [NSLayoutConstraint constraintWithItem:_fileBrowserView
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1
                                                              constant:_fileBrowserWidth];
  _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
  [_myConstraints addObject:_fileBrowserWidthConstraint];
}

- (void)resetCursorRects {
  [self addCursorRect:self.fileBrowserResizeRect cursor:[NSCursor resizeLeftRightCursor]];
}

- (NSView *)hitTest:(NSPoint)aPoint {
  if (NSMouseInRect([self convertPoint:aPoint fromView:self.superview], self.fileBrowserResizeRect, self.isFlipped)) {
    return self;
  }

  return [super hitTest:aPoint];
}

- (void)mouseDown:(NSEvent *)anEvent {
  if (_mouseDownRecursionGuard) {
    return;
  }

  _mouseDownRecursionGuard = YES;

  NSView *view = nil;
  NSPoint mouseDownPos = [self convertPoint:anEvent.locationInWindow fromView:nil];
  if (NSMouseInRect(mouseDownPos, self.fileBrowserResizeRect, self.isFlipped)) {
    view = _fileBrowserView;
  }

  if (!view || anEvent.type != NSLeftMouseDown) {
    [super mouseDown:anEvent];
  } else {
    if (_fileBrowserView) {
      _fileBrowserWidthConstraint.constant = NSWidth(_fileBrowserView.frame);
      _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
    }

    NSEvent *mouseDownEvent = anEvent;
    CGRect initialFrame = view.frame;

    BOOL didDrag = NO;
    while (anEvent.type != NSLeftMouseUp) {
      anEvent = [NSApp nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseDown | NSLeftMouseUpMask)
                                   untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES];
      if (anEvent.type != NSLeftMouseDragged) {
        break;
      }

      CGPoint mouseCurrentPos = [self convertPoint:anEvent.locationInWindow fromView:nil];
      if (!didDrag &&
          SQ(fabs(mouseDownPos.x - mouseCurrentPos.x)) + SQ(fabs(mouseDownPos.y - mouseCurrentPos.y)) < SQ(1)) {

        continue; // we didn't even drag a pixel
      }

      if (view == _fileBrowserView) {
        CGFloat width = NSWidth(initialFrame) + (mouseCurrentPos.x - mouseDownPos.x) * (_fileBrowserOnRight ? -1 : +1);
        NSUInteger targetWidth = (NSUInteger) MAX(50, round(width));
        _fileBrowserWidth = targetWidth - targetWidth % _dragIncrement;

        _fileBrowserWidthConstraint.constant = _fileBrowserWidth;
        _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow - 1;
      }

      [self.window invalidateCursorRectsForView:self];
      didDrag = YES;
    }

    if (!didDrag) {
      NSView *hitView = [super hitTest:[self.superview convertPoint:[mouseDownEvent locationInWindow] fromView:nil]];
      if (hitView && hitView != self) {
        [NSApp postEvent:anEvent atStart:NO];
        [hitView mouseDown:mouseDownEvent];
      }
    }

    _fileBrowserWidthConstraint.priority = NSLayoutPriorityDragThatCannotResizeWindow;
  }

  _mouseDownRecursionGuard = NO;
}

#pragma mark Private
- (id)replaceView:(NSView *)oldView withView:(NSView *)newView {
  if (newView == oldView) {
    return oldView;
  }

  [oldView removeFromSuperview];

  if (newView) {
    newView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:newView];
  }

  self.needsUpdateConstraints = YES;
  return newView;
}

- (void)addVimViewMinSizeConstraints {
  _vimViewWidthConstraint = [NSLayoutConstraint constraintWithItem:_vimView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1
                                                          constant:_vimView.minSize.width];
  _vimViewHeightConstraint = [NSLayoutConstraint constraintWithItem:_vimView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationGreaterThanOrEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1
                                                           constant:_vimView.minSize.height];
  [_myConstraints addObject:_vimViewWidthConstraint];
  [_myConstraints addObject:_vimViewHeightConstraint];
}

- (CGRect)fileBrowserResizeRect {
  if (!_fileBrowserView) {
    return CGRectZero;
  }
  CGRect r = _fileBrowserView.frame;
  return CGRectMake(_fileBrowserOnRight ? NSMinX(r) - 3 : NSMaxX(r) - 4, NSMinY(r), 10, NSHeight(r));
}

@end
