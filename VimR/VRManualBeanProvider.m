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


@interface VRManualBeanProvider : NSObject <TBManualBeanProvider>
@end

@implementation VRManualBeanProvider

// TODO: why did I use a static method here? Use an instance method (TBD in TBCacao)
+ (NSArray *)beanContainers {
    static NSArray *manualBeans;

    if (manualBeans == nil) {
        VRWorkspaceController *workspaceController = [[VRWorkspaceController alloc] init];

        /**
        * TODO: MMVimController uses [MMVimManager sharedManager].
        * At some point, we should get rid of that and use alloc + init.
        * For time being, let's accept this and use the shared manager here.
        */
        MMVimManager *vimManager = [MMVimManager sharedManager];

        workspaceController.vimManager = vimManager;
        vimManager.delegate = workspaceController;
        [vimManager setUp];

        manualBeans = @[
                [TBBeanContainer beanContainerWithBean:workspaceController],
                [TBBeanContainer beanContainerWithBean:vimManager],
                [TBBeanContainer beanContainerWithBean:[NSWorkspace sharedWorkspace]],
        ];
    }

    return manualBeans;
}

@end
