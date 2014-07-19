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


@interface VRNoPluginPreviewView : NSView <VRPluginPreviewView>

#pragma mark NSView
- (id)initWithFrame:(NSRect)frameRect;

#pragma mark VRPluginPreviewView
- (BOOL)previewFileAtUrl:(NSURL *)url;

@end
