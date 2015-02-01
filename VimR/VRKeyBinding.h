/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>


@interface VRKeyBinding : NSObject

@property (readonly, nonatomic, copy) NSString *keyEquivalent;
@property (readonly, nonatomic) NSEventModifierFlags modifiers;
@property (readonly, nonatomic) NSInteger tag;
@property (readonly, nonatomic) SEL action;

- (instancetype)initWithAction:(SEL)anAction modifiers:(NSEventModifierFlags)modifiers keyEquivalent:(NSString *)charCode tag:(NSUInteger)tag;

@end
