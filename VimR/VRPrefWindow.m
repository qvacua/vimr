/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRPrefWindow.h"
#import "VRUtils.h"
#import "VRUserDefaults.h"


NSString *const qPrefWindowFrameAutosaveName = @"pref-window-frame-autosave";


#define CONSTRAIN(fmt, ...) [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat: fmt, ##__VA_ARGS__] options:0 metrics:nil views:views]];


@implementation VRPrefWindow {
}

@autowire(userDefaultsController)

#pragma mark NSWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
  self = [super initWithContentRect:contentRect styleMask:NSTitledWindowMask | NSClosableWindowMask
                            backing:NSBackingStoreBuffered defer:YES];
  RETURN_NIL_WHEN_NOT_SELF

  self.title = @"Preferences";
  self.releasedWhenClosed = NO;
  [self setFrameAutosaveName:qPrefWindowFrameAutosaveName];

  return self;
}

- (void)addViews {
  NSButton *syncWorkingDirWithVimPwdButton = [[NSButton alloc] initWithFrame:CGRectZero];
  syncWorkingDirWithVimPwdButton.translatesAutoresizingMaskIntoConstraints = NO;
  syncWorkingDirWithVimPwdButton.buttonType = NSSwitchButton;
  syncWorkingDirWithVimPwdButton.bezelStyle = NSThickSquareBezelStyle;
  syncWorkingDirWithVimPwdButton.title = @"Keep the working directory in sync with Vim's 'pwd'";
  [self.contentView addSubview:syncWorkingDirWithVimPwdButton];

  [syncWorkingDirWithVimPwdButton bind:NSValueBinding toObject:_userDefaultsController
                           withKeyPath:SF(@"values.%@", qDefaultSyncWorkingDirectoryWithVimPwd) options:nil];

  NSDictionary *views = @{
      @"syncWorkingDir" : syncWorkingDirWithVimPwdButton,
  };

  CONSTRAIN(@"H:|-[syncWorkingDir]-|");
  CONSTRAIN(@"V:|-[syncWorkingDir]-|");
}

#pragma mark TBInitializingBean
- (void)postConstruct {
  [self addViews];
}

@end
