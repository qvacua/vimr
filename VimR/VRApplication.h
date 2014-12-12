/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>


@interface VRKeyShortcutItem : NSObject

@property (readonly, nonatomic, copy) NSString *keyEquivalent;
@property (readonly, nonatomic) NSInteger tag;
@property (readonly, nonatomic) SEL action;

- (instancetype)initWithAction:(SEL)anAction keyEquivalent:(NSString *)charCode tag:(NSUInteger)tag;

@end


@interface VRApplication : NSApplication

- (id)init;
- (void)addKeyShortcutItems:(NSArray *)items;
- (void)sendEvent:(NSEvent *)theEvent;

- (NSArray *)orderedMainWindows;

@end
