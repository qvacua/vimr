/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import <TBCacao/TBCacao.h>
#import <MacVimFramework/MacVimFramework.h>
#import "VRDocumentController.h"


@interface VRManualBeanProvider : NSObject <TBManualBeanProvider>
@end

@implementation VRManualBeanProvider

+ (NSArray *)beanContainers {
    static NSArray *manualBeans;

    if (manualBeans == nil) {
        VRDocumentController *documentController = [[VRDocumentController alloc] init];
        MMVimManager *vimManager = [[MMVimManager alloc] init];

        documentController.vimManager = vimManager;
        vimManager.delegate = documentController;
        [vimManager setUp];

        manualBeans = @[
                [TBBeanContainer beanContainerWithBean:documentController],
                [TBBeanContainer beanContainerWithBean:vimManager],
        ];
    }

    return manualBeans;
}

@end
