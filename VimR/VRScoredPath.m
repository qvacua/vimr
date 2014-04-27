/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRScoredPath.h"
#import "VRUtils.h"
#import "NSURL+VR.h"


@implementation VRScoredPath

#pragma mark Public
- (instancetype)initWithPath:(NSString *)path score:(double)score {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _score = score;
  _path = path;
  _displayName = SF(@"%@  —  %@/", _path.lastPathComponent, [[NSURL fileURLWithPath:_path] parentName]);

  return self;
}

#pragma mark NSObject
- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.score=%f", self.score];
  [description appendFormat:@", self.path=%@", self.path];
  [description appendString:@">"];
  return description;
}

@end
