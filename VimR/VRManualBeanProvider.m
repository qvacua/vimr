/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <TBCacao/TBCacao.h>
#import <MacVimFramework/MacVimFramework.h>
#import "VRWorkspaceController.h"
#import "VRPropertyReader.h"


static NSString *const qVimrRcFileName = @".vimr_rc";


@interface VRManualBeanProvider : NSObject <TBManualBeanProvider>
@end


@implementation VRManualBeanProvider

// TODO: why did I use a static method here? Use an instance method (TBD in TBCacao)
+ (NSArray *)beanContainers {
  static NSArray *manualBeans;

  if (manualBeans == nil) {
    VRWorkspaceController *workspaceController = [[VRWorkspaceController alloc] init];
    workspaceController.application = NSApp;

    /**
    * TODO: MMVimController uses [MMVimManager sharedManager].
    * At some point, we should get rid of that and use alloc + init.
    * For time being, let's accept this and use the shared manager here.
    */
    MMVimManager *vimManager = [MMVimManager sharedManager];
    vimManager.delegate = workspaceController;
    [vimManager setUp];

    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:qVimrRcFileName];
    VRPropertyReader *propertyReader = [[VRPropertyReader alloc] initWithPropertyFileUrl:[NSURL fileURLWithPath:path]];
    propertyReader.fileManager = [NSFileManager defaultManager];

    manualBeans = @[
        [TBBeanContainer beanContainerWithBean:workspaceController],
        [TBBeanContainer beanContainerWithBean:vimManager],
        [TBBeanContainer beanContainerWithBean:[NSWorkspace sharedWorkspace]],
        [TBBeanContainer beanContainerWithBean:[NSFileManager defaultManager]],
        [TBBeanContainer beanContainerWithBean:[NSNotificationCenter defaultCenter]],
        [TBBeanContainer beanContainerWithBean:[NSUserDefaults standardUserDefaults]],
        [TBBeanContainer beanContainerWithBean:[NSUserDefaultsController sharedUserDefaultsController]],
        [TBBeanContainer beanContainerWithBean:[NSFontManager sharedFontManager]],
        [TBBeanContainer beanContainerWithBean:[NSBundle mainBundle]],
        [TBBeanContainer beanContainerWithBean:propertyReader],
    ];
  }

  return manualBeans;
}

@end
