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


#define CONSTRAIN(fmt) [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]];


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
  NSTextField *fbbTitle = [self newTextLabelWithString:@"File Browser Behavior:"];
  fbbTitle.alignment = NSRightTextAlignment;

  NSButton *showFoldersFirstButton =
      [self checkButtonWithTitle:@"Show folders first" defaultKey:qDefaultShowFoldersFirst];

  NSButton *syncWorkingDirWithVimPwdButton =
      [self checkButtonWithTitle:@"Keep the working directory in sync with Vim's 'pwd'"
                      defaultKey:qDefaultSyncWorkingDirectoryWithVimPwd];

  NSButton *showHiddenFilesButton =
      [self checkButtonWithTitle:@"Show hidden files" defaultKey:qDefaultShowHiddenInFileBrowser];


  NSTextField *fbbDescription = [self newTextLabelWithString:
      @"These are default values, ie new windows will start with these values set:\n"
          "– The changes will only affect new windows.\n"
          "– You can override these settings in each window."];
  fbbDescription.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
  fbbDescription.textColor = [NSColor grayColor];
  [fbbDescription.cell setWraps:YES];
  [fbbDescription.cell setUsesSingleLineMode:NO];

  NSTextField *dobTitle = [self newTextLabelWithString:@"Default Opening Behavior:"];
  dobTitle.alignment = NSRightTextAlignment;

  NSPopUpButton *dobButton = [[NSPopUpButton alloc] initWithFrame:CGRectZero pullsDown:NO];
  dobButton.translatesAutoresizingMaskIntoConstraints = NO;
  [dobButton.menu addItemWithTitle:@"Open in a new tab" action:NULL keyEquivalent:@""];
  [dobButton.menu addItemWithTitle:@"Open in the current tab" action:NULL keyEquivalent:@""];
  [dobButton.menu addItemWithTitle:@"Open in a vertical split" action:NULL keyEquivalent:@""];
  [dobButton.menu addItemWithTitle:@"Open in a horizontal split" action:NULL keyEquivalent:@""];
  [dobButton bind:NSSelectedIndexBinding toObject:_userDefaultsController
      withKeyPath:SF(@"values.%@", qDefaultDefaultOpeningBehavior)
          options:@{
              NSValueTransformerBindingOption : [[VROpenModeValueTransformer alloc] init]
          }];
  [self.contentView addSubview:dobButton];

  NSDictionary *views = @{
      @"fbbTitle" : fbbTitle,
      @"showFoldersFirst" : showFoldersFirstButton,
      @"showHidden" : showHiddenFilesButton,
      @"syncWorkingDir" : syncWorkingDirWithVimPwdButton,
      @"fbbDesc" : fbbDescription,

      @"dobTitle" : dobTitle,
      @"dobMenu" : dobButton,
  };

  CONSTRAIN(@"H:|-[fbbTitle]-[showFoldersFirst]-|");
  CONSTRAIN(@"H:|-[fbbTitle]-[showHidden]-|");
  CONSTRAIN(@"H:|-[fbbTitle]-[syncWorkingDir]-|");
  CONSTRAIN(@"H:|-[fbbTitle]-[fbbDesc]-|");

  CONSTRAIN(@"H:|-[dobTitle]-[showFoldersFirst]");
  CONSTRAIN(@"H:[dobTitle]-[dobMenu]");

  [self.contentView addConstraint:[self baseLineConstraintForView:fbbTitle toView:showFoldersFirstButton]];
  [self.contentView addConstraint:[self baseLineConstraintForView:dobTitle toView:dobButton]];
  CONSTRAIN(@"V:|-[showFoldersFirst]-[showHidden]-[syncWorkingDir]-[fbbDesc]-[dobMenu]-|");
}

- (NSLayoutConstraint *)baseLineConstraintForView:(NSView *)targetView toView:(NSView *)referenceView {
  return [NSLayoutConstraint constraintWithItem:targetView attribute:NSLayoutAttributeBaseline
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:referenceView
                                      attribute:NSLayoutAttributeBaseline
                                     multiplier:1 constant:0];
}

- (NSTextField *)newTextLabelWithString:(NSString *)string {
  NSTextField *textField = [[NSTextField alloc] initWithFrame:CGRectZero];
  textField.translatesAutoresizingMaskIntoConstraints = NO;
  textField.backgroundColor = [NSColor clearColor];
  textField.stringValue = string;
  textField.editable = NO;
  textField.bordered = NO;

  [self.contentView addSubview:textField];

  return textField;
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
