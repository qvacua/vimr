/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>


static NSString *const qPrefPaneNotImplementedExceptionName = @"PrefPaneNotImplementedException";


@interface VRPrefPane : NSView

@property (nonatomic, weak) NSUserDefaultsController *userDefaultsController;

#pragma mark Public
- (NSString *)displayName;
- (NSTextField *)newDescriptionLabelWithString:(NSString *)string alignment:(NSTextAlignment)alignment;
- (NSLayoutConstraint *)baseLineConstraintForView:(NSView *)targetView toView:(NSView *)referenceView;
- (NSTextField *)newTextLabelWithString:(NSString *)string alignment:(NSTextAlignment)alignment;
- (NSButton *)checkButtonWithTitle:(NSString *)title defaultKey:(NSString *)defaultKey;

#pragma mark NSview
- (BOOL)isFlipped;

@end
