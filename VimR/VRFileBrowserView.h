/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import "VRMovementsAndActionsProtocol.h"


@class VRFileItem;
@class VRFileItemManager;
@class VROutlineView;


@interface VRNode : NSObject

@property (nonatomic) NSURL *url;
@property (nonatomic) id item;
@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *children;
@property (nonatomic, getter=isDir) BOOL dir;
@property (nonatomic, getter=isHidden) BOOL hidden;

- (NSString *)description;

@end


@interface VRFileBrowserView : NSView <
    NSOutlineViewDataSource, NSOutlineViewDelegate,
    VRMovementsAndActionsProtocol>

@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;

@property (nonatomic) NSURL *rootUrl;

@property (readonly) VROutlineView *fileOutlineView;

#pragma mark Public
- (instancetype)initWithRootUrl:(NSURL *)rootUrl;
- (BOOL)syncWorkspaceWithPwd;
- (void)dealloc;
- (void)setUp;

#pragma mark IBActions
- (IBAction)toggleShowHiddenFiles:(id)sender;

#pragma mark NSOutlineViewDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index1 ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

#pragma mark NSView
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item;
- (BOOL)mouseDownCanMoveWindow;

@end
