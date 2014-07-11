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


extern NSString *const qPrefWindowFrameAutosaveName;
extern NSString *const qOpenInNewTabDescription;
extern NSString *const qOpenInCurrentTabDescription;
extern NSString *const qOpenInVerticalSplitDescription;
extern NSString *const qOpenInHorizontalSplitDescription;

@interface VRPrefWindow : NSWindow <TBBean, TBInitializingBean>

@property (nonatomic, weak) NSUserDefaultsController *userDefaultsController;

#pragma mark NSWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;

#pragma mark TBInitializingBean
- (void)postConstruct;

@end
