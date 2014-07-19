/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRMarkdownPlugin.h"


@implementation VRMarkdownPlugin {

}

#pragma mark VRPlugin
- (NSArray *)fileTypes {
  return @[@"markdown"];
}

- (NSArray *)abilities {
  return @[qPluginAbilityPreview];
}

- (NSView <VRPluginPreviewView> *)previewView {
  return nil;
}

#pragma mark NSObject
- (NSString *)description {
  return [NSString stringWithFormat:@"<%@>", NSStringFromClass([self class])];
}

@end
