/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


extern NSString *const qDefaultShowHiddenInFileBrowser;
extern NSString *const qDefaultSyncWorkingDirectoryWithVimPwd;
extern NSString *const qDefaultShowFoldersFirst;
extern NSString *const qDefaultDefaultOpeningBehavior;

typedef enum {
  VROpenModeInNewTab,
  VROpenModeInCurrentTab,
  VROpenModeInVerticalSplit,
  VROpenModeInHorizontalSplit
} VROpenMode;

/**
* string of VROpenMode -> index (enum)
*/
@interface VROpenModeValueTransformer : NSValueTransformer
@end
