/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

@protocol NeoVimUi

- (void)modeChange:(int)mode;
- (void)put:(NSString *)string;

@end