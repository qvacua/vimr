/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VRFileBrowserPrefPane.h"
#import "VRUserDefaults.h"
#import "VRUtils.h"


NSString *const qOpenInNewTabDescription = @"Opens in a new tab";
NSString *const qOpenInCurrentTabDescription = @"Opens in the current tab";
NSString *const qOpenInVerticalSplitDescription = @"Opens in a vertical split";
NSString *const qOpenInHorizontalSplitDescription = @"Opens in a horizontal split";


#define CONSTRAIN(fmt) [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:fmt options:0 metrics:nil views:views]];


@implementation VRFileBrowserPrefPane {
  VROpenModeValueTransformer *_openModeTransformer;

  NSPopUpButton *_defaultOpenModeButton;
  NSTextField *_noModifierDescription;
  NSTextField *_cmdDescription;
  NSTextField *_optDescription;
  NSTextField *_ctrlDescription;
}

#pragma mark VRPrefPane
- (NSString *)displayName {
  return @"File Browser";
}

#pragma mark Public
- (id)initWithUserDefaultsController:(NSUserDefaultsController *)userDefaultsController {
  self = [super initWithFrame:CGRectZero];
  RETURN_NIL_WHEN_NOT_SELF

  self.userDefaultsController = userDefaultsController;
  _openModeTransformer = [[VROpenModeValueTransformer alloc] init];

  [self addViews];

  return self;
}

#pragma mark Private
- (void)addViews {
  // file browser behavior
  NSTextField *fbbTitle = [self newTextLabelWithString:@"File Browser Behavior:" alignment:NSRightTextAlignment];

  NSButton *showFoldersFirstButton = [self checkButtonWithTitle:@"Show folders first" defaultKey:qDefaultShowFoldersFirst];
  NSButton *syncWorkingDirWithVimPwdButton = [self checkButtonWithTitle:@"Keep the working directory in sync with Vim's 'pwd'" defaultKey:qDefaultSyncWorkingDirectoryWithVimPwd];
  NSButton *showHiddenFilesButton = [self checkButtonWithTitle:@"Show hidden files" defaultKey:qDefaultShowHiddenInFileBrowser];

  NSTextField *fbbDescription = [self            newTextLabelWithString:
      @"These are default values, ie new windows will start with these values set:\n"
          "– The changes will only affect new windows.\n"
          "– You can override these settings in each window." alignment:NSLeftTextAlignment];
  fbbDescription.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
  fbbDescription.textColor = [NSColor grayColor];
  [fbbDescription.cell setWraps:YES];
  [fbbDescription.cell setUsesSingleLineMode:NO];

  // default opening behavior
  NSTextField *domTitle = [self newTextLabelWithString:@"Default Opening Behavior:" alignment:NSRightTextAlignment];

  _defaultOpenModeButton = [[NSPopUpButton alloc] initWithFrame:CGRectZero pullsDown:NO];
  _defaultOpenModeButton.translatesAutoresizingMaskIntoConstraints = NO;
  [_defaultOpenModeButton setAction:@selector(defaultOpenBehaviorAction:)];
  [_defaultOpenModeButton.menu addItemWithTitle:@"Open in a new tab" action:NULL keyEquivalent:@""];
  [_defaultOpenModeButton.menu addItemWithTitle:@"Open in the current tab" action:NULL keyEquivalent:@""];
  [_defaultOpenModeButton.menu addItemWithTitle:@"Open in a vertical split" action:NULL keyEquivalent:@""];
  [_defaultOpenModeButton.menu addItemWithTitle:@"Open in a horizontal split" action:NULL keyEquivalent:@""];
  [_defaultOpenModeButton bind:NSSelectedIndexBinding toObject:self.userDefaultsController
                   withKeyPath:SF(@"values.%@", qDefaultDefaultOpeningBehavior)
                       options:@{NSValueTransformerBindingOption : _openModeTransformer}];
  [self addSubview:_defaultOpenModeButton];

  NSTextField *noModifierTitle = [self newDescriptionLabelWithString:@"Open:" alignment:NSRightTextAlignment];
  NSTextField *cmdTitle = [self newDescriptionLabelWithString:@"⌃⌥-Open:" alignment:NSRightTextAlignment];
  NSTextField *optTitle = [self newDescriptionLabelWithString:@"⌥-Open:" alignment:NSRightTextAlignment];
  NSTextField *ctrlTitle = [self newDescriptionLabelWithString:@"⌃-Open:" alignment:NSRightTextAlignment];

  _noModifierDescription = [self newDescriptionLabelWithString:qOpenInNewTabDescription alignment:NSLeftTextAlignment];
  _cmdDescription = [self newDescriptionLabelWithString:qOpenInCurrentTabDescription alignment:NSLeftTextAlignment];
  _optDescription = [self newDescriptionLabelWithString:qOpenInVerticalSplitDescription alignment:NSLeftTextAlignment];
  _ctrlDescription = [self newDescriptionLabelWithString:qOpenInHorizontalSplitDescription alignment:NSLeftTextAlignment];
  [self defaultOpenBehaviorAction:_defaultOpenModeButton];

  NSDictionary *views = @{
      @"fbbTitle" : fbbTitle,
      @"showFoldersFirst" : showFoldersFirstButton,
      @"showHidden" : showHiddenFilesButton,
      @"syncWorkingDir" : syncWorkingDirWithVimPwdButton,
      @"fbbDesc" : fbbDescription,

      @"domTitle" : domTitle,
      @"domMenu" : _defaultOpenModeButton,
      @"noModifierTitle" : noModifierTitle,
      @"cmdTitle" : cmdTitle,
      @"optTitle" : optTitle,
      @"ctrlTitle" : ctrlTitle,
      @"noModifierDesc" : _noModifierDescription,
      @"cmdDesc" : _cmdDescription,
      @"optDesc" : _optDescription,
      @"ctrlDesc" : _ctrlDescription,
  };

  for (NSView *view in @[domTitle, noModifierTitle, cmdTitle, optTitle, ctrlTitle]) {
    [self addConstraint:[NSLayoutConstraint constraintWithItem:view
                                                     attribute:NSLayoutAttributeTrailing
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:fbbTitle
                                                     attribute:NSLayoutAttributeTrailing
                                                    multiplier:1 constant:0]];
  }

  for (NSView *view in views.allValues) {
    [view setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
  }

  CONSTRAIN(@"H:|-[fbbTitle]-[showFoldersFirst]-|");
  CONSTRAIN(@"H:|-[fbbTitle]-[showHidden]-|");
  CONSTRAIN(@"H:|-[fbbTitle]-[syncWorkingDir]-|");
  CONSTRAIN(@"H:|-[fbbTitle]-[fbbDesc]-|");

  CONSTRAIN(@"H:|-[domTitle]-[domMenu]"); // the domMenu should not be stretched
  CONSTRAIN(@"H:|-[noModifierTitle]-[noModifierDesc]-|");
  CONSTRAIN(@"H:|-[cmdTitle]-[cmdDesc]-|");
  CONSTRAIN(@"H:|-[optTitle]-[optDesc]-|");
  CONSTRAIN(@"H:|-[ctrlTitle]-[ctrlDesc]-|");

  [self addConstraint:[self baseLineConstraintForView:fbbTitle toView:showFoldersFirstButton]];
  [self addConstraint:[self baseLineConstraintForView:domTitle toView:_defaultOpenModeButton]];

  CONSTRAIN(@"V:|-[showFoldersFirst]-[showHidden]-[syncWorkingDir]-[fbbDesc]-"
      "[domMenu]-[noModifierTitle][cmdTitle][optTitle][ctrlTitle]-|");
  CONSTRAIN(@"V:[domMenu]-[noModifierDesc][cmdDesc][optDesc][ctrlDesc]");
}

- (IBAction)defaultOpenBehaviorAction:(id)sender {
  NSString *mode = [_openModeTransformer reverseTransformedValue:@([sender indexOfSelectedItem])];
  if ([mode isEqualToString:qOpenModeInNewTabValue]) {
    _noModifierDescription.stringValue = qOpenInNewTabDescription;
    _cmdDescription.stringValue = qOpenInCurrentTabDescription;
    _optDescription.stringValue = qOpenInVerticalSplitDescription;
    _ctrlDescription.stringValue = qOpenInHorizontalSplitDescription;
    return;
  }

  if ([mode isEqualToString:qOpenModeInCurrentTabValue]) {
    _noModifierDescription.stringValue = qOpenInCurrentTabDescription;
    _cmdDescription.stringValue = qOpenInNewTabDescription;
    _optDescription.stringValue = qOpenInVerticalSplitDescription;
    _ctrlDescription.stringValue = qOpenInHorizontalSplitDescription;
    return;
  }

  if ([mode isEqualToString:qOpenModeInVerticalSplitValue]) {
    _noModifierDescription.stringValue = qOpenInVerticalSplitDescription;
    _cmdDescription.stringValue = qOpenInCurrentTabDescription;
    _optDescription.stringValue = qOpenInNewTabDescription;
    _ctrlDescription.stringValue = qOpenInHorizontalSplitDescription;
    return;
  }

  if ([mode isEqualToString:qOpenModeInHorizontalSplitValue]) {
    _noModifierDescription.stringValue = qOpenInHorizontalSplitDescription;
    _cmdDescription.stringValue = qOpenInCurrentTabDescription;
    _optDescription.stringValue = qOpenInVerticalSplitDescription;
    _ctrlDescription.stringValue = qOpenInNewTabDescription;
    return;
  }
}

@end
