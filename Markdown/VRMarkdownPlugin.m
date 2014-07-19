/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRMarkdownPlugin.h"
#import "VRMarkdownPreviewView.h"


@implementation VRMarkdownPlugin {

}

#pragma mark VRPlugin
- (NSArray *)fileTypes {
  return @[@"markdown"];
}

- (NSArray *)abilities {
  return @[qPluginAbilityPreview];
}

- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType {
  return [[VRMarkdownPreviewView alloc] initWithFrame:CGRectZero];
}

@end
