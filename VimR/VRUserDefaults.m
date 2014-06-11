/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRUserDefaults.h"


NSString *const qDefaultShowHiddenInFileBrowser = @"show-hidden-files-in-file-browser";
NSString *const qDefaultSyncWorkingDirectoryWithVimPwd = @"sync-working-directory-with-vim-pwd";
NSString *const qDefaultShowFoldersFirst = @"show-folder-first";
NSString *const qDefaultDefaultOpeningBehavior = @"default-opening-behavior";

NSString *const qOpenModeInNewTabValue = @"in-new-tab";
NSString *const qOpenModeInCurrentTabValue = @"in-current-tab";
NSString *const qOpenModeInVerticalSplitValue = @"in-vertical-split-tab";
NSString *const qOpenModeInHorizontalSplitValue = @"in-horizontal-split-tab";


@implementation VROpenModeValueTransformer

+ (Class)transformedValueClass {
  return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
  return YES;
}

- (id)transformedValue:(id)value {
  if ([value isEqualTo:qOpenModeInNewTabValue]) {
    return [NSNumber numberWithUnsignedInteger:VROpenModeInNewTab];
  }

  if ([value isEqualTo:qOpenModeInCurrentTabValue]) {
    return [NSNumber numberWithUnsignedInteger:VROpenModeInCurrentTab];
  }

  if ([value isEqualTo:qOpenModeInVerticalSplitValue]) {
    return [NSNumber numberWithUnsignedInteger:VROpenModeInVerticalSplit];
  }

  if ([value isEqualTo:qOpenModeInHorizontalSplitValue]) {
    return [NSNumber numberWithUnsignedInteger:VROpenModeInHorizontalSplit];
  }

  return [NSNumber numberWithUnsignedInteger:VROpenModeInNewTab];
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
