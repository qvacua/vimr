/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import "VRUserDefaults.h"


@interface VRNode : NSObject

@property (nonatomic) NSURL *url;
@property (nonatomic) id item;
@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *children;
@property (nonatomic, getter=isDir) BOOL dir;
@property (nonatomic, getter=isHidden) BOOL hidden;

- (NSString *)description;

@end


@protocol VRFileBrowserActionDelegate <NSObject>

- (void)actionOpenDefault;
- (void)actionOpenInNewTab;
- (void)actionOpenInCurrentTab;
- (void)actionOpenInVerticalSplit;
- (void)actionOpenInHorizontalSplit;
- (void)actionSearch:(NSString *)string;
- (void)actionReverseSearch:(NSString *)string;
- (void)actionMoveDown;
- (void)actionMoveToBottom;
- (void)actionMoveToTop;
- (void)actionMoveUp;
- (void)actionFocusVimView;
- (BOOL)actionCanActOnNode;
- (BOOL)actionNodeIsDirectory;
- (void)actionAddPath:(NSString *)path;
- (void)actionMoveToPath:(NSString *)path;
- (void)actionDelete;
- (void)actionCopyToPath:(NSString *)path;
- (BOOL)actionCheckClobberForPath:(NSString *)path;
- (void)actionIgnore;

- (void)updateStatusMessage:(NSString *)message;

@end


typedef enum {
  VRFileBrowserActionModeNormal,
  VRFileBrowserActionModeSearch,
  VRFileBrowserActionModeMenu,
  VRFileBrowserActionModeMenuAdd,
  VRFileBrowserActionModeMenuMove,
  VRFileBrowserActionModeMenuCopy,
  VRFileBrowserActionModeMenuDelete,
  VRFileBrowserActionModeConfirmation,
} VRFileBrowserActionMode;


@interface VRFileBrowserOutlineView : NSOutlineView

@property (nonatomic) id<VRFileBrowserActionDelegate> actionDelegate;
@property (nonatomic, readonly) VRFileBrowserActionMode actionMode;
@property (nonatomic, readonly) VRFileBrowserActionMode actionSubMode;

- (VRNode *)selectedItem;
- (void)actionReset;

@end
