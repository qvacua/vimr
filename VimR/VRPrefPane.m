/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <PureLayout/ALView+PureLayout.h>
#import "VRPrefPane.h"
#import "VRUtils.h"


@implementation VRPrefPane

#pragma mark  Public
- (NSString *)displayName {
  @throw [NSException exceptionWithName:qPrefPaneNotImplementedExceptionName reason:@"The subclass must implement this method" userInfo:nil];
}

- (NSTextField *)newDescriptionLabelWithString:(NSString *)string alignment:(NSTextAlignment)alignment {
  NSTextField *field = [self newTextLabelWithString:string alignment:alignment];
  field.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
  field.textColor = [NSColor grayColor];

  return field;
}

- (NSLayoutConstraint *)baseLineConstraintForView:(NSView *)targetView toView:(NSView *)referenceView {
  return [NSLayoutConstraint constraintWithItem:targetView attribute:NSLayoutAttributeBaseline
                                      relatedBy:NSLayoutRelationEqual
                                         toItem:referenceView
                                      attribute:NSLayoutAttributeBaseline
                                     multiplier:1 constant:0];
}

- (NSTextField *)newTextLabelWithString:(NSString *)string alignment:(NSTextAlignment)alignment {
  NSTextField *field = [[NSTextField alloc] initForAutoLayout];
  field.translatesAutoresizingMaskIntoConstraints = NO;
  field.backgroundColor = [NSColor clearColor];
  field.stringValue = string;
  field.editable = NO;
  field.bordered = NO;
  field.alignment = alignment;

  [self addSubview:field];

  return field;
}

- (NSButton *)checkButtonWithTitle:(NSString *)title defaultKey:(NSString *)defaultKey {
  NSButton *checkButton = [[NSButton alloc] initForAutoLayout];
  checkButton.translatesAutoresizingMaskIntoConstraints = NO;
  checkButton.title = title;
  checkButton.buttonType = NSSwitchButton;
  checkButton.bezelStyle = NSThickSquareBezelStyle;

  [checkButton bind:NSValueBinding toObject:_userDefaultsController withKeyPath:SF(@"values.%@", defaultKey) options:nil];

  [self addSubview:checkButton];

  return checkButton;
}

#pragma mark NSView
- (BOOL)isFlipped {
  return YES; // such that the pref pane view is placed at the left top corner of the scroll view
}

@end
