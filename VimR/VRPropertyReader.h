/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Cocoa/Cocoa.h>


@class VRKeyBinding;


extern NSString *const qOpenQuicklyIgnorePatterns;
extern NSString *const qSelectNthTabActive;
extern NSString *const qSelectNthTabModifier;


@interface VRPropertyReader : NSObject

@property (nonatomic, weak) NSFileManager *fileManager;
@property (readonly, nonatomic) NSArray *keysForKeyBindings;
@property (readonly, nonatomic) NSDictionary *workspaceProperties;
@property (readonly, nonatomic) NSDictionary *globalProperties;

- (instancetype)initWithPropertyFileUrl:(NSURL *)url;

- (BOOL)useSelectNthTabBindings;
- (NSEventModifierFlags)selectNthTabModifiers;
- (VRKeyBinding *)keyBindingForKey:(NSString *)key;

@end
