/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import "VRUserDefaultsObserver.h"
#import "VRFileItemCacheInvalidationObserver.h"


@class VRFileItem;
@class VRFileItemManager;
@class VRFileBrowserOutlineView;
@class VRNode;
@class VRWorkspaceView;
@class MMVimController;

@protocol VRFileBrowserActionDelegate;


@interface VRFileBrowserView : NSView <NSOutlineViewDataSource, NSOutlineViewDelegate,
    VRUserDefaultsObserver,
    VRFileItemCacheInvalidationObserver,
    VRFileBrowserActionDelegate>

@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;
@property (nonatomic, weak) MMVimController *vimController;

@property (nonatomic) NSURL *rootUrl;

@property (weak) VRWorkspaceView *workspaceView;
@property (readonly) VRFileBrowserOutlineView *fileOutlineView;

#pragma mark Public
- (instancetype)initWithRootUrl:(NSURL *)rootUrl;
- (void)setUp;
- (void)reload;

#pragma mark IBActions
- (IBAction)focusVimView:(id)sender;

#pragma mark NSOutlineViewDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index1 ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

#pragma mark NSOutlineViewDelegate
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn
                   item:(VRNode *)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item;

#pragma mark NSView
- (BOOL)mouseDownCanMoveWindow;

#pragma mark VRUserDefaultsObserver
- (void)registerUserDefaultsObservation;
- (void)removeUserDefaultsObservation;

#pragma mark VRFileItemCacheInvalidationObserver
- (void)registerFileItemCacheInvalidationObservation;
- (void)removeFileItemCacheInvalidationObservation;

#pragma mark NSObject
- (void)dealloc;

@end
