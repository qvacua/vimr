/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRGeneralPrefPane.h"
#import "VRUserDefaults.h"
#import "VRUtils.h"


#define CONSTRAIN(fmt) [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]];


@implementation VRGeneralPrefPane

- (NSString *)name {
  return @"General";
}

- (NSString *)displayName {
  return @"general";
}

- (id)initWithUserDefaultsController:(NSUserDefaultsController *)userDefaultsController {
  self = [super initWithFrame:CGRectZero];
  RETURN_NIL_WHEN_NOT_SELF

  self.userDefaultsController = userDefaultsController;
  [self addViews];

  return self;
}


- (void)addViews {
  // default appearance
  NSTextField *daTitle = [self newTextLabelWithString:@"Default Appearance:" alignment:NSRightTextAlignment];
  NSButton *showStatusBarButton = [self checkButtonWithTitle:@"Show status bar" defaultKey:qDefaultShowStatusBar];
  NSButton *showSidebarButton = [self checkButtonWithTitle:@"Show sidebar" defaultKey:qDefaultShowSideBar];
  NSButton *showSidebarOnRightButton = [self checkButtonWithTitle:@"Sidebar on right" defaultKey:qDefaultShowSideBarOnRight];

  // auto saving
  NSTextField *asTitle = [self newTextLabelWithString:@"Saving Behavior:" alignment:NSRightTextAlignment];

  NSButton *asOnFrameDeactivation = [self checkButtonWithTitle:@"Save automatically on focus loss" defaultKey:qDefaultAutoSaveOnFrameDeactivation];
  NSTextField *asOfdDesc = [self newDescriptionLabelWithString:@"'autocmd BufLeave,FocusLost * silent! wall' in VimR group" alignment:NSLeftTextAlignment];

  NSButton *asOnCursorHold = [self checkButtonWithTitle:@"Save automatically if VimR is idle for some time" defaultKey:qDefaultAutoSaveOnCursorHold];
  NSTextField *asOchDesc = [self newDescriptionLabelWithString:@"'autocmd CursorHold * silent! wall' in VimR group" alignment:NSLeftTextAlignment];

  NSDictionary *views = @{
      @"daTitle" : daTitle,
      @"showStatusBar" : showStatusBarButton,
      @"showSidebar" : showSidebarButton,
      @"showSidebarRight" : showSidebarOnRightButton,

      @"asTitle" : asTitle,
      @"asOnFrameDeactivation" : asOnFrameDeactivation,
      @"asOfdDesc" : asOfdDesc,
      @"asOnCursorHold" : asOnCursorHold,
      @"asOchDesc" : asOchDesc,
  };

  for (NSView *view in @[asTitle]) {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:daTitle
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1 constant:0]];
  }

  for (NSView *view in views.allValues) {
    [view setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
  }

  CONSTRAIN(@"H:|-[daTitle]-[showStatusBar]-|");
  CONSTRAIN(@"H:|-[daTitle]-[showSidebar]-|");
  CONSTRAIN(@"H:|-[daTitle]-[showSidebarRight]-|");

  CONSTRAIN(@"H:|-[asTitle]-[asOnFrameDeactivation]-|");
  CONSTRAIN(@"H:|-[asTitle]-[asOfdDesc]-|");
  CONSTRAIN(@"H:|-[asTitle]-[asOnCursorHold]-|");
  CONSTRAIN(@"H:|-[asTitle]-[asOchDesc]-|");

  [self addConstraint:[self baseLineConstraintForView:daTitle toView:showStatusBarButton]];
  [self addConstraint:[self baseLineConstraintForView:asTitle toView:asOnFrameDeactivation]];

  CONSTRAIN(@"V:|-[showStatusBar]-[showSidebar]-[showSidebarRight]-(24)-[asOnFrameDeactivation]-[asOfdDesc]-[asOnCursorHold]-[asOchDesc]-|");
}

@end
