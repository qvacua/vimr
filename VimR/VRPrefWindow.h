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
static NSString *const qOpenInNewTabDescription = @"Opens in a new tab";
static NSString *const qOpenInCurrentTabDescription = @"Opens in the current tab:";
static NSString *const qOpenInVerticalSplitDescription = @"Opens in a vertical split";
static NSString *const qOpenInHorizontalSplitDescription = @"Opens in a horizontal split";

@interface VRPrefWindow : NSWindow <TBBean, TBInitializingBean>

@property (nonatomic, weak) NSUserDefaultsController *userDefaultsController;

#pragma mark NSWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag;

#pragma mark TBInitializingBean
- (void)postConstruct;

@end
