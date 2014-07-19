/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRPlugin.h"


NSString *const qPluginAbilityPreview = @"plugin-ability-preview";
const NSUInteger qPluginDefinitionVersion = 1;


@implementation VRPlugin

- (NSUInteger)pluginDefinitionVersion {
  return qPluginDefinitionVersion;
}

- (NSUInteger)version {
  return (NSUInteger) [[NSBundle bundleForClass:self.class].infoDictionary[@"CFBundleVersion"] integerValue];
}

- (NSString *)identifier {
  return [NSBundle bundleForClass:self.class].infoDictionary[@"CFBundleIdentifier"];
}

- (NSArray *)fileTypes {
  return @[];
}

- (NSArray *)abilities {
  return @[];
}

- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType{
  return nil;
}

@end
