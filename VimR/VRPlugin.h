/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>
#import "VRPluginPreviewView.h"


extern NSString *const qPluginAbilityPreview;
extern const NSUInteger qPluginDefinitionVersion;


@interface VRPlugin : NSObject

/**
* On the basis of this VimR will determine whether it will be able to use this plugin or not. You must not override
* this method.
*
* @must-not-override
* @since 1
*/
- (NSUInteger)pluginDefinitionVersion;

/**
* The own version of the plugin. The default implementation returns the CFBundleVersion of the plugin. You can however
* return a different value.
*
* @optional
* @since 1
*/
- (NSUInteger)version;

/**
* The bundle identifier of the plugin. The default implementation returns the CFBundleIdentifier of the plugin. It is
* not recommended to change this behavior.
*
* @optional
* @since 1
*/
- (NSString *)identifier;

/**
* Return the file types for which the plugin wants to be activated. The array must contain file types as recognized by
* Vim, eg
*
* return @[@"conf", @"config", @"context"];
*
* To list all file types known to Vim, issue the following
*
* :echo join(map(split(globpath(&rtp, 'ftplugin/*.vim'), '\n'), 'fnamemodify(v:val, ":t:r")'), "\n")
*
* (http://superuser.com/questions/664638/list-all-filetype-plugins-known-to-vim)
*
* @required
* @since 1
*/
- (NSArray *)fileTypes;

/**
* Return what the plugin can do, cf qPluginAbility*. For instance
*
* return @[qPluginAbilityPreview];
*
* @required
* @since 1
*/
- (NSArray *)abilities;

/**
* The plugin can return a preview view for the given fileType (as returned by -fileTypes).
* This method has to return a new view instance each time it is called. This view will be added to the
* appropriate parent view and will be set to be automatically resized. Initialize your view with CGRectZero.
*
* @optional
* @since 1
*/
- (NSView <VRPluginPreviewView> *)previewViewForFileType:(NSString *)fileType;

@end
