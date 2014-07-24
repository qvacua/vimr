/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>


static NSString *const qNotImplementedExceptionName = @"NotImplementedException";


@interface VRPrefPane : NSView

@property (nonatomic, weak) NSUserDefaultsController *userDefaultsController;

- (NSString *)prefPaneIdentifier;
- (NSString *)name;
- (NSString *)displayName;

- (NSTextField *)newDescriptionLabelWithString:(NSString *)string alignment:(NSTextAlignment)alignment;
- (NSLayoutConstraint *)baseLineConstraintForView:(NSView *)targetView toView:(NSView *)referenceView;
- (NSTextField *)newTextLabelWithString:(NSString *)string alignment:(NSTextAlignment)alignment;
- (NSButton *)checkButtonWithTitle:(NSString *)title defaultKey:(NSString *)defaultKey;

@end
