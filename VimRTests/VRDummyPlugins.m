/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRDummyPlugins.h"


@implementation VRDummyPluginA {

}

- (NSString *)identifier {
  return @"a";
}

- (NSArray *)fileTypes {
  return @[@"type-a-1", @"type-a-2"];
}

- (NSArray *)abilities {
  return @[qPluginAbilityPreview];
}

- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType {
  return [[VRDummyViewA alloc] init];
}

@end

@implementation VRDummyPluginB {

}

- (NSString *)identifier {
  return @"b";
}

- (NSArray *)fileTypes {
  return @[@"type-b-1"];
}

- (NSArray *)abilities {
  return @[qPluginAbilityPreview];
}

- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType {
  return [[VRDummyViewB alloc] init];
}

@end

@implementation VRDummyPluginC {

}

- (NSString *)identifier {
  return @"c";
}

- (NSArray *)fileTypes {
  return @[@"type-c-1", @"type-c-2", @"type-c-3"];
}

- (NSArray *)abilities {
  return @[qPluginAbilityPreview];
}

- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType {
  if ([fileType hasSuffix:@"2"]) {
    return [[VRDummyViewC2 alloc] init];
  }

  return [[VRDummyViewC1 alloc] init];
}

@end

@implementation VRDummyPluginD

- (NSUInteger)pluginDefinitionVersion {
  return 0;
}

- (NSArray *)fileTypes {
  return @[@"type-d-1"];
}

- (NSArray *)abilities {
  return @[qPluginAbilityPreview];
}

- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType {
  return [[VRDummyViewA alloc] init];
}

@end

@implementation VRDummyPluginE

- (NSUInteger)pluginDefinitionVersion {
  return 999999999;
}

- (NSArray *)fileTypes {
  return @[@"type-e-1"];
}

- (NSArray *)abilities {
  return @[qPluginAbilityPreview];
}

- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType {
  return [[VRDummyViewA alloc] init];
}

@end

@implementation VRDummyViewA
@end

@implementation VRDummyViewB
@end

@implementation VRDummyViewC1
@end

@implementation VRDummyViewC2
@end
