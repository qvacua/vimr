/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>


@interface VRKeyShortcut : NSObject

@property (readonly, nonatomic, copy) NSString *keyEquivalent;
@property (readonly, nonatomic) NSInteger tag;
@property (readonly, nonatomic) SEL action;

- (instancetype)initWithAction:(SEL)anAction keyEquivalent:(NSString *)charCode tag:(NSUInteger)tag;

@end


@interface VRApplication : NSApplication

- (id)init;
- (void)addKeyShortcutItems:(NSArray *)items;
- (void)sendEvent:(NSEvent *)theEvent;

#pragma mark Public
/**
* This method is used by AppleScript to get the list of open main windows.
*/
- (NSArray *)orderedMainWindows;

@end
