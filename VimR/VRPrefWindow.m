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


@implementation VRPrefWindow

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

#pragma mark TBInitializingBean
- (void)postConstruct {
  [self addViews];
}

#pragma mark Private
- (void)addViews {
  NSButton *syncWorkingDirWithVimPwdButton =
      [self checkButtonWithTitle:@"Keep the working directory in sync with Vim's 'pwd'"
                      defaultKey:qDefaultSyncWorkingDirectoryWithVimPwd];

  NSButton *showFoldersFirstButton =
      [self checkButtonWithTitle:@"Show folders first in the file browser" defaultKey:qDefaultShowFoldersFirst];

  NSButton *showHiddenFilesButton =
      [self checkButtonWithTitle:@"Show hidden files in the file browser" defaultKey:qDefaultShowHiddenInFileBrowser];

  NSTextField *label = [[NSTextField alloc] initWithFrame:CGRectZero];
  label.translatesAutoresizingMaskIntoConstraints = NO;
  label.backgroundColor = [NSColor clearColor];
  [label setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
  [label.cell setWraps:YES];
  [label.cell setUsesSingleLineMode:NO];
  label.stringValue = @"These are default values, ie new windows will start with these values set.\n"
      "You can override them in each window.";
  label.editable = NO;
  label.bordered = NO;
  [self.contentView addSubview:label];

  NSDictionary *views = @{
      @"syncWorkingDir" : syncWorkingDirWithVimPwdButton,
      @"showFoldersFirst" : showFoldersFirstButton,
      @"showHidden" : showHiddenFilesButton,
      @"label" : label,
  };

  CONSTRAIN(@"H:|-[syncWorkingDir]-|");
  CONSTRAIN(@"H:|-[showFoldersFirst]-|");
  CONSTRAIN(@"H:|-[showHidden]-|");
  CONSTRAIN(@"H:|-[label]-|");
  CONSTRAIN(@"V:|-[syncWorkingDir]-[showFoldersFirst]-[showHidden]-[label]-|");
}

- (NSButton *)checkButtonWithTitle:(NSString *)title defaultKey:(NSString *)defaultKey {
  NSButton *checkButton = [[NSButton alloc] initWithFrame:CGRectZero];
  checkButton.translatesAutoresizingMaskIntoConstraints = NO;
  checkButton.title = title;
  checkButton.buttonType = NSSwitchButton;
  checkButton.bezelStyle = NSThickSquareBezelStyle;

  [checkButton bind:NSValueBinding toObject:_userDefaultsController withKeyPath:SF(@"values.%@", defaultKey)
            options:nil];

  [self.contentView addSubview:checkButton];

  return checkButton;
}

@end
