/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>
#import "VRFileItemCacheInvalidationObserver.h"


@class VRMainWindowController;
@class VRPluginManager;


@interface VRPreviewWindowController : NSWindowController <VRFileItemCacheInvalidationObserver>

@property (nonatomic, weak) NSNotificationCenter *notificationCenter;
@property (nonatomic, weak) VRPluginManager *pluginManager;

#pragma mark Public
- (instancetype)initWithMainWindowController:(VRMainWindowController *)mainWindowController;
- (void)setUp;
- (void)updatePreview;

#pragma mark VRFileItemCacheInvalidationObserver
- (void)registerFileItemCacheInvalidationObservation;
- (void)removeFileItemCacheInvalidationObservation;

#pragma mark IBActions
- (IBAction)refreshPreview:(id)sender;

#pragma mark NSObject
- (void)dealloc;

@end
