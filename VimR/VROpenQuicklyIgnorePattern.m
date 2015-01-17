/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import "VROpenQuicklyIgnorePattern.h"
#import "VRUtils.h"
#import "NSString+VR.h"


@implementation VROpenQuicklyIgnorePattern {
  NSString *_targetPattern;
}

- (instancetype)initWithPattern:(NSString *)pattern {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _pattern = pattern.copy;

  if ([pattern hasPrefix:@"*/"]) {
    _targetPattern = SF(@"%@/", [pattern substringFromIndex:1]);
    _kind = VROpenQuicklyIgnoreFolderPattern;
  } else if ([pattern hasPrefix:@"*"]) {
    _targetPattern = [pattern substringFromIndex:1];
    _kind = VROpenQuicklyIgnoreSuffixPattern;
  } else if ([pattern hasSuffix:@"*"]) {
    _targetPattern = [pattern substringWithRange:NSMakeRange(0, pattern.length - 1)];
    _kind = VROpenQuicklyIgnorePrefixPattern;
  } else {
    _targetPattern = pattern.copy;
    _kind = VROpenQuicklyIgnoreExactPattern;
  }

  return self;
}

- (BOOL)matchesPath:(__weak NSString *)absolutePath {
  switch (_kind) {
    case VROpenQuicklyIgnoreFolderPattern:
      return [[absolutePath stringByAppendingString:@"/"] hasString:_targetPattern];
    case VROpenQuicklyIgnoreSuffixPattern:
      return [absolutePath.lastPathComponent hasSuffix:_targetPattern];
    case VROpenQuicklyIgnorePrefixPattern:
      return [absolutePath.lastPathComponent hasPrefix:_targetPattern];
    case VROpenQuicklyIgnoreExactPattern:
      return [absolutePath.lastPathComponent isEqualToString:_targetPattern];
  }

  return NO;
}

@end
