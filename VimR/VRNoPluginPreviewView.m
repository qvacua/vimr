/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <WebKit/WebKit.h>
#import "VRNoPluginPreviewView.h"
#import "VRUtils.h"


#define CONSTRAINT(fmt) [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]]


@implementation VRNoPluginPreviewView {
  WebView *_webView;
}

#pragma mark NSView
- (id)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  RETURN_NIL_WHEN_NOT_SELF

  _webView = [[WebView alloc] initWithFrame:CGRectZero];
  _webView.translatesAutoresizingMaskIntoConstraints = NO;
  [self addSubview:_webView];

  NSDictionary *views = @{
      @"webView" : _webView,
  };

  CONSTRAINT(@"H:|[webView]|");
  CONSTRAINT(@"V:|[webView]|");

  return self;
}

#pragma mark VRPluginPreviewView
- (BOOL)previewFileAtUrl:(NSURL *)url {
  NSURL *htmlUrl = [[NSBundle mainBundle] URLForResource:@"error" withExtension:@"html"];
  [_webView.mainFrame loadRequest:[NSURLRequest requestWithURL:htmlUrl]];

  return YES;
}

@end
