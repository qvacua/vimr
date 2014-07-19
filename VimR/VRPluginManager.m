/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRPluginManager.h"
#import "VRUtils.h"
#import "VRPlugin.h"
#import "VRDefaultLogSetting.h"
#import "NSArray+VR.h"
#import "VRNoPluginPreviewView.h"


static NSString *const qPluginBundleExtension = @"vimr-plugin";
static const NSUInteger qMinPluginDefinitionVersion = 1;
static const NSUInteger qMaxPluginDefinitionVersion = 1;


@implementation VRPluginManager {
  NSMutableDictionary *_plugins;
  NSMutableDictionary *_pluginsForPreview;
}

@autowire(fileManager)

#pragma mark Public
- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType {
  if (blank(fileType)) {
    return [[VRNoPluginPreviewView alloc] initWithFrame:CGRectZero];
  }

  NSView <VRPluginPreviewView> *previewView = [_pluginsForPreview[fileType] previewViewForFileType:fileType];

  if (previewView == nil) {
    return [[VRNoPluginPreviewView alloc] initWithFrame:CGRectZero];
  }

  return previewView;
}

#pragma mark TBInitializingBean
- (void)postConstruct {
  [self loadPlugins];
  [self categorizePlugins];
}

#pragma mark NSObject
- (id)init {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _plugins = [[NSMutableDictionary alloc] initWithCapacity:10];
  _pluginsForPreview = [[NSMutableDictionary alloc] initWithCapacity:10];

  return self;
}

#pragma mark Private
- (void)loadPlugins {
  NSArray *plugins = [self pluginPaths];

  if (plugins.isEmpty) {
    DDLogInfo(@"There are no built in plugins to load.");
    return;
  }

  for (NSString *pluginPath in plugins) {
    [self loadPluginAtPath:pluginPath];
  }
}

- (void)categorizePlugins {
  for (VRPlugin *plugin in _plugins.allValues) {
    [self checkAndAddForPreview:plugin];
  }
}

- (void)checkAndAddForPreview:(VRPlugin *)plugin {
  if ([plugin.abilities containsObject:qPluginAbilityPreview]) {
    for (NSString *fileType in plugin.fileTypes) {
      _pluginsForPreview[fileType] = plugin;
    }
  }
}

- (NSArray *)pluginPaths {
  // TODO: scan also ~/Library/Application Support/VimR/PlugIns
  NSString *builtInPlugInsPath = [NSBundle mainBundle].builtInPlugInsPath;

  NSError *error = nil;
  NSArray *possiblePlugins = [_fileManager contentsOfDirectoryAtPath:builtInPlugInsPath error:&error];
  if (error) {
    // TODO: notify the user about this!
    DDLogWarn(@"The built in plugin folder could not be read. No built in plugins are loaded: %@", error);
    return @[];
  }

  NSArray *plugins = [possiblePlugins filteredArrayUsingPredicate:
      [NSPredicate predicateWithBlock:^BOOL(NSString *path, NSDictionary *bindings) {
        return [path.pathExtension isEqualToString:qPluginBundleExtension];
      }]
  ];

  NSMutableArray *pluginPaths = [[NSMutableArray alloc] initWithCapacity:plugins.count];
  for (NSString *plugin in plugins) {
    [pluginPaths addObject:[builtInPlugInsPath stringByAppendingPathComponent:plugin]];
  }

  return pluginPaths;
}

- (void)loadPluginAtPath:(NSString *)pluginPath {
  NSBundle *bundle = [NSBundle bundleWithPath:pluginPath];

  NSError *error = nil;
  BOOL success = [bundle loadAndReturnError:&error];
  if (!success) {
    // TODO: notify the user about this!
    DDLogWarn(@"The bundle for the plugin at %@ could not be loaded.", pluginPath);
    return;
  }

  VRPlugin *plugin = [[bundle.principalClass alloc] init];
  if (![self isCompatible:plugin]) {
    DDLogWarn(@"The plugin %@ at %@ is not compatible: %lu < min(%lu) or  %lu > max(%lu).",
            plugin.identifier, pluginPath,
            plugin.pluginDefinitionVersion, qMinPluginDefinitionVersion,
            plugin.pluginDefinitionVersion, qMaxPluginDefinitionVersion);

    return;
  }

  _plugins[plugin.identifier] = plugin;
  DDLogInfo(@"Plugin %@ loaded.", plugin.identifier);
}

- (BOOL)isCompatible:(VRPlugin *)plugin {
  if (plugin.pluginDefinitionVersion < qMinPluginDefinitionVersion) {
    return NO;
  }

  if (plugin.pluginDefinitionVersion > qMaxPluginDefinitionVersion) {
    return NO;
  }

  return YES;
}

@end
