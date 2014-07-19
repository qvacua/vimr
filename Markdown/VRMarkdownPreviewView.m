/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <WebKit/WebKit.h>
#import <OCDiscount/OCDiscount.h>
#import "VRMarkdownPreviewView.h"


#define CONSTRAINT(fmt) [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]]


@implementation VRMarkdownPreviewView {
  WebView *_webView;
}

- (id)initWithFrame:(NSRect)frameRect {
  self = [super initWithFrame:frameRect];
  if (!self) {return nil;}

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

- (BOOL)previewFileAtUrl:(NSURL *)url {
  NSString *markdown = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:NULL];
  NSString *html = [markdown htmlFromMarkdown];

  [_webView.mainFrame loadHTMLString:html baseURL:url.URLByDeletingLastPathComponent];

  return YES;
}

@end
