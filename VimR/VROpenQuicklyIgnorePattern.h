/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Foundation/Foundation.h>


typedef enum {
  VROpenQuicklyIgnoreFolderPattern,
  VROpenQuicklyIgnoreSuffixPattern,
  VROpenQuicklyIgnorePrefixPattern,
  VROpenQuicklyIgnoreExactPattern,
} VROpenQuicklyIgnorePatternKind;


@interface VROpenQuicklyIgnorePattern : NSObject

@property (nonatomic, copy, readonly) NSString *pattern;
@property (nonatomic, readonly) VROpenQuicklyIgnorePatternKind kind;

- (instancetype)initWithPattern:(NSString *)pattern;


- (BOOL)matchesPath:(NSString *)absolutePath;

@end
