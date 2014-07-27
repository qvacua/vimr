/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>
#import <TBCacao/TBCacao.h>


@class VRPrefPane;


extern NSString *const qPrefWindowFrameAutosaveName;


@interface VRPrefWindow : NSWindow <
    TBBean, TBInitializingBean,
    NSOutlineViewDataSource, NSOutlineViewDelegate>

@property (nonatomic, weak) NSUserDefaultsController *userDefaultsController;

#pragma mark NSWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;

#pragma mark TBInitializingBean
- (void)postConstruct;

#pragma mark NSOutlineViewDelegate
- (void)outlineViewSelectionDidChange:(NSNotification *)notification;

#pragma mark NSOutlineViewDataSource
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(VRPrefPane *)pane;
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;

@end
