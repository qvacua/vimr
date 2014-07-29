/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRUserDefaults.h"


NSString *const qDefaultShowStatusBar = @"show-status-bar";
NSString *const qDefaultShowSideBar = @"show-side-bar";
NSString *const qDefaultShowSideBarOnRight = @"show-side-bar-on-right";

NSString *const qDefaultOpenUntitledWindowModeOnLaunch = @"open-untitled-window-on-launch";
NSString *const qDefaultOpenUntitledWindowModeOnReactivation = @"open-untitled-window-on-reactivation";

NSString *const qDefaultShowHiddenInFileBrowser = @"show-hidden-files-in-file-browser";
NSString *const qDefaultSyncWorkingDirectoryWithVimPwd = @"sync-working-directory-with-vim-pwd";
NSString *const qDefaultShowFoldersFirst = @"show-folder-first";
NSString *const qDefaultHideWildignoreInFileBrowser = @"hide-wildignore-in-file-browser";

NSString *const qDefaultDefaultOpeningBehavior = @"default-opening-behavior";
NSString *const qOpenModeInNewTabValue = @"in-new-tab";
NSString *const qOpenModeInCurrentTabValue = @"in-current-tab";
NSString *const qOpenModeInVerticalSplitValue = @"in-vertical-split-tab";
NSString *const qOpenModeInHorizontalSplitValue = @"in-horizontal-split-tab";

NSString *const qDefaultAutoSaveOnFrameDeactivation = @"auto-save-on-frame-deactivation";
NSString *const qDefaultAutoSaveOnCursorHold = @"auto-save-on-cursor-hold";

VROpenMode open_mode_from_modifier(NSUInteger modifierFlags, VROpenMode defaultMode) {
  BOOL optionKey = (modifierFlags & NSAlternateKeyMask) != 0;
  BOOL controlKey = (modifierFlags & NSControlKeyMask) != 0;

  if (optionKey && controlKey) {
    return defaultMode == VROpenModeInCurrentTab ? VROpenModeInNewTab : VROpenModeInCurrentTab;
  }

  if (optionKey) {
    return defaultMode == VROpenModeInVerticalSplit ? VROpenModeInNewTab : VROpenModeInVerticalSplit;
  }

  if (controlKey) {
    return defaultMode == VROpenModeInHorizontalSplit ? VROpenModeInNewTab : VROpenModeInHorizontalSplit;
  }

  return defaultMode;
}


VROpenMode open_mode_from_event(NSEvent *curEvent, NSString *defaultModeString) {
  VROpenModeValueTransformer *transformer = [[VROpenModeValueTransformer alloc] init];
  VROpenMode defaultMode = (VROpenMode) [[transformer transformedValue:defaultModeString] unsignedIntegerValue];

  return open_mode_from_modifier(curEvent.modifierFlags, defaultMode);
}


@implementation VROpenModeValueTransformer

+ (Class)transformedValueClass {
  return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
  return YES;
}

- (id)transformedValue:(id)value {
  if ([value isEqualTo:qOpenModeInNewTabValue]) {
    return @(VROpenModeInNewTab);
  }

  if ([value isEqualTo:qOpenModeInCurrentTabValue]) {
    return @(VROpenModeInCurrentTab);
  }

  if ([value isEqualTo:qOpenModeInVerticalSplitValue]) {
    return @(VROpenModeInVerticalSplit);
  }

  if ([value isEqualTo:qOpenModeInHorizontalSplitValue]) {
    return @(VROpenModeInHorizontalSplit);
  }

  return @(VROpenModeInNewTab);
}

- (id)reverseTransformedValue:(id)value {
  switch ([value unsignedIntegerValue]) {
    case VROpenModeInNewTab:
      return qOpenModeInNewTabValue;
    case VROpenModeInCurrentTab:
      return qOpenModeInCurrentTabValue;
    case VROpenModeInVerticalSplit:
      return qOpenModeInVerticalSplitValue;
    case VROpenModeInHorizontalSplit:
      return qOpenModeInHorizontalSplitValue;
    default:
      return qOpenModeInNewTabValue;
  }
}

@end
