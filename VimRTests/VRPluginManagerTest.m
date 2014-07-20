/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRBaseTestCase.h"
#import "VRPluginManager.h"
#import "VRDummyPlugins.h"
#import "VRNoPluginPreviewView.h"


static NSBundle *mainBundle;
static NSBundle *pluginBundleA;
static NSBundle *pluginBundleB;
static NSBundle *pluginBundleC;
static NSBundle *pluginBundleD;
static NSBundle *pluginBundleE;


@interface VRPluginManagerTest : VRBaseTestCase
@end

@implementation VRPluginManagerTest {
  VRPluginManager *pluginManager;

  NSFileManager *fileManager;

  IMP mainBundleSelector;
  IMP bundleWithPathSelector;
}

+ (NSBundle *)mockMainBundle {
  return mainBundle;
}

+ (NSBundle *)mockBundleWithPath:(NSString *)path {
  if ([path hasPrefix:@"built-in-path/a"]) {
    return pluginBundleA;
  }

  if ([path hasPrefix:@"built-in-path/b"]) {
    return pluginBundleB;
  }

  if ([path hasPrefix:@"built-in-path/c"]) {
    return pluginBundleC;
  }

  if ([path hasPrefix:@"built-in-path/d"]) {
    return pluginBundleD;
  }

  if ([path hasPrefix:@"built-in-path/e"]) {
    return pluginBundleE;
  }

  return nil;
}

- (void)setUp {
  [super setUp];

  mainBundle = mock([NSBundle class]);
  pluginBundleA = mock([NSBundle class]);
  pluginBundleB = mock([NSBundle class]);
  pluginBundleC = mock([NSBundle class]);
  pluginBundleD = mock([NSBundle class]);
  pluginBundleE = mock([NSBundle class]);

  mainBundleSelector = [self mockClassSelector:@selector(mainBundle) ofClass:[NSBundle class]
                                  withSelector:@selector(mockMainBundle) ofClass:[self class]];
  bundleWithPathSelector = [self mockClassSelector:@selector(bundleWithPath:) ofClass:[NSBundle class]
                                      withSelector:@selector(mockBundleWithPath:) ofClass:[self class]];

  [given([mainBundle builtInPlugInsPath]) willReturn:@"built-in-path"];

  [given([pluginBundleA principalClass]) willReturn:[VRDummyPluginA class]];
  [given([pluginBundleB principalClass]) willReturn:[VRDummyPluginB class]];
  [given([pluginBundleC principalClass]) willReturn:[VRDummyPluginC class]];
  [given([pluginBundleD principalClass]) willReturn:[VRDummyPluginD class]];
  [given([pluginBundleE principalClass]) willReturn:[VRDummyPluginE class]];

  [[given([pluginBundleA loadAndReturnError:NULL]) withMatcher:anything()] willReturnBool:YES];
  [[given([pluginBundleB loadAndReturnError:NULL]) withMatcher:anything()] willReturnBool:YES];
  [[given([pluginBundleC loadAndReturnError:NULL]) withMatcher:anything()] willReturnBool:YES];
  [[given([pluginBundleD loadAndReturnError:NULL]) withMatcher:anything()] willReturnBool:YES];
  [[given([pluginBundleE loadAndReturnError:NULL]) withMatcher:anything()] willReturnBool:YES];

  fileManager = mock([NSFileManager class]);
  [[given([fileManager contentsOfDirectoryAtPath:@"built-in-path" error:NULL]) withMatcher:anything() forArgument:1]
      willReturn:@[ @"a.vimr-plugin", @"b.vimr-plugin", @"c.vimr-plugin", @"d.vimr-plugin", @"e.vimr-plugin" ]];

  pluginManager = [[VRPluginManager alloc] init];
  pluginManager.fileManager = fileManager;

  [pluginManager postConstruct];
}

- (void)tearDown {
  [self restoreClassSelector:@selector(mainBundle) ofClass:[NSBundle class] withImpl:mainBundleSelector];
  [self restoreClassSelector:@selector(bundleWithPath:) ofClass:[NSBundle class] withImpl:bundleWithPathSelector];
}

- (void)testPreviewViewForFileType {
  assertThat([pluginManager previewViewForFileType:@"type-a-1"], instanceOf([VRDummyViewA class]));
  assertThat([pluginManager previewViewForFileType:@"type-a-2"], instanceOf([VRDummyViewA class]));

  assertThat([pluginManager previewViewForFileType:@"type-b-1"], instanceOf([VRDummyViewB class]));

  assertThat([pluginManager previewViewForFileType:@"type-c-1"], instanceOf([VRDummyViewC1 class]));
  assertThat([pluginManager previewViewForFileType:@"type-c-2"], instanceOf([VRDummyViewC2 class]));
  assertThat([pluginManager previewViewForFileType:@"type-c-3"], instanceOf([VRDummyViewC1 class]));

  assertThat([pluginManager previewViewForFileType:@"type-d-1"], instanceOf([VRNoPluginPreviewView class]));
  assertThat([pluginManager previewViewForFileType:@"type-e-1"], instanceOf([VRNoPluginPreviewView class]));
}

@end
