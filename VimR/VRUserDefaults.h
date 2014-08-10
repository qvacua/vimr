/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Foundation/Foundation.h>


extern NSString *const qDefaultShowStatusBar;
extern NSString *const qDefaultShowSideBar;
extern NSString *const qDefaultShowSideBarOnRight;

extern NSString *const qDefaultOpenUntitledWinModeOnLaunch;
extern NSString *const qDefaultOpenUntitledWinModeOnReactivation;

extern NSString *const qDefaultFileBrowserShowFoldersFirst;
extern NSString *const qDefaultFileBrowserShowHidden;
extern NSString *const qDefaultFileBrowserSyncWorkingDirWithVimPwd;
extern NSString *const qDefaultFileBrowserHideWildignore;

extern NSString *const qDefaultFileBrowserOpeningBehavior;

extern NSString *const qOpenModeInNewTabValue;
extern NSString *const qOpenModeInCurrentTabValue;
extern NSString *const qOpenModeInVerticalSplitValue;
extern NSString *const qOpenModeInHorizontalSplitValue;

extern NSString *const qDefaultAutoSaveOnFrameDeactivation;
extern NSString *const qDefaultAutoSaveOnCursorHold;


typedef enum {
  VROpenModeInNewTab,
  VROpenModeInCurrentTab,
  VROpenModeInVerticalSplit,
  VROpenModeInHorizontalSplit
} VROpenMode;


OBJC_EXTERN inline VROpenMode open_mode_from_modifier(NSUInteger modifierFlags, VROpenMode defaultMode);
OBJC_EXTERN inline VROpenMode open_mode_from_event(NSEvent *curEvent, NSString *defaultModeString);


/**
* string of VROpenMode -> index (enum)
*/
@interface VROpenModeValueTransformer : NSValueTransformer
@end
