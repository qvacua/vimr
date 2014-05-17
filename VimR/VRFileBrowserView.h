/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@class VRFileItem;
@class VRFileItemManager;


@interface VRFileBrowserView : NSView <NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) VRFileItemManager *fileItemManager;
@property (nonatomic, weak) NSUserDefaults *userDefaults;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;

@property (nonatomic, copy) NSURL *rootUrl;


#pragma mark Public
- (instancetype)initWithRootUrl:(NSURL *)rootUrl;
- (void)dealloc;
- (void)setUp;

#pragma mark IBActions
- (IBAction)toggleShowHiddenFiles:(id)sender;

#pragma mark NSOutlineViewDataSource
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index1 ofItem:(id)item;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn
           byItem:(id)item;

#pragma mark NSView
- (BOOL)mouseDownCanMoveWindow;

@end
