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


@protocol VRPluginPreviewView;


@interface VRPluginManager : NSObject <TBBean, TBInitializingBean>

@property (weak) NSFileManager *fileManager;

#pragma mark Public
- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType;

#pragma mark TBInitializingBean
- (void)postConstruct;

#pragma mark NSObject
- (id)init;

@end
