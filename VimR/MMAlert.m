/* vi:set ts=8 sts=4 sw=4 ft=objc:
 *
 * VIM - Vi IMproved		by Bram Moolenaar
 *				MacVim GUI port by Bjorn Winckler
 *
 * Do ":help uganda"  in Vim to read copying and usage conditions.
 * Do ":help credits" in Vim to see a list of people who contributed.
 * See README.txt for an overview of the Vim source code.
 *
 * Minor modifications by Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 */

#import "MMAlert.h"


static int MMAlertTextFieldHeight = 22;


@implementation MMAlert

- (void)setTextFieldString:(NSString *)textFieldString {
    @synchronized (self) {
        _textField = [[NSTextField alloc] init];
        _textField.stringValue = textFieldString;
    }
}

- (void)setInformativeText:(NSString *)text {
    if (self.textField) {
        // HACK! Add some space for the text field.
        super.informativeText = [text stringByAppendingString:@"\n\n\n"];
    } else {
        super.informativeText = text;
    }
}

- (void)beginSheetModalForWindow:(NSWindow *)window modalDelegate:(id)delegate didEndSelector:(SEL)didEndSelector
                     contextInfo:(void *)contextInfo {

    [super beginSheetModalForWindow:window modalDelegate:delegate didEndSelector:didEndSelector
                        contextInfo:contextInfo];

    // HACK! Place the input text field at the bottom of the informative text
    // (which has been made a bit larger by adding newline characters).
    NSView *contentView = [self.window contentView];
    NSRect rect = contentView.frame;
    rect.origin.y = rect.size.height;

    for (NSView *view in contentView.subviews) {
        if ([view isKindOfClass:[NSTextField class]] && view.frame.origin.y < rect.origin.y) {
            // NOTE: The informative text field is the lowest NSTextField in the alert dialog.
            rect = view.frame;
        }
    }

    rect.size.height = MMAlertTextFieldHeight;
    self.textField.frame = rect;

    [contentView addSubview:self.textField];
    [self.textField becomeFirstResponder];
}

@end
