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

@property (nonatomic, copy) NSString *keyEquivalent;
@property (nonatomic) NSInteger tag;
@property (nonatomic) SEL action;

/**
* By default:
* - tag = 0
*/
- (instancetype)initWithAction:(SEL)anAction keyEquivalent:(NSString *)charCode tag:(NSUInteger)tag;

@end


@interface VRApplication : NSApplication

@property (nonatomic, readonly) NSArray *keyShortcutItems;

- (void)addKeyShortcutItems:(NSArray *)items;

- (void)sendEvent:(NSEvent *)theEvent;

@end
