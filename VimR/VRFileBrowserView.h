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
- (void)setUp;
- (void)reload;

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

#pragma mark VRMovementsAndActionsProtocol
- (void)viMotionLeft:(id)sender event:(NSEvent *)event;
- (void)viMotionUp:(id)sender event:(NSEvent *)event;
- (void)viMotionDown:(id)sender event:(NSEvent *)event;
- (void)viMotionRight:(id)sender event:(NSEvent *)event;
- (void)actionSpace:(id)sender event:(NSEvent *)event;
- (void)actionCarriageReturn:(id)sender event:(NSEvent *)event;
- (void)actionEscape:(id)sender event:(NSEvent *)event;

#pragma mark NSView
- (BOOL)mouseDownCanMoveWindow;

#pragma mark NSObject
- (void)dealloc;

@end
