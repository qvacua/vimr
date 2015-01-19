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
#import <fnmatch.h>


@implementation VROpenQuicklyIgnorePattern {
  const char *_pattern;
}

- (instancetype)initWithPattern:(NSString *)pattern {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  char const *patternAsCStr = pattern.fileSystemRepresentation;
  _pattern = malloc(sizeof(char) * strlen(patternAsCStr));

  strcpy(_pattern, patternAsCStr);

  return self;
}

- (BOOL)matchesPath:(NSString *)absolutePath {
  int matches;

  if (_pattern[0] == '*' && _pattern[1] == '/') {
    // folder
    matches = fnmatch(_pattern, absolutePath.fileSystemRepresentation, FNM_LEADING_DIR);
  } else {
    matches = fnmatch(_pattern, absolutePath.lastPathComponent.fileSystemRepresentation, 0);
  }

  return matches != FNM_NOMATCH;
}

@end
