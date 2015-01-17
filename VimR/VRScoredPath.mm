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
#import "NSString+VR.h"

#import <cf/cf.h>
#import <text/ranker.h>


static inline double rank_string(NSString *string, NSString *target, std::vector<std::pair<size_t, size_t> > *out = NULL) {
  return oak::rank(cf::to_s((__bridge CFStringRef) string), cf::to_s((__bridge CFStringRef) target), out);
}


@implementation VRScoredPath

#pragma mark Public
- (instancetype)initWithUrl:(NSURL *)url {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF

  _score = 0;
  _url = url;

  return self;
}

- (void)computeScoreForCandidate:(NSString *)candidate {
  NSString *preparedStr;
  if ([candidate hasString:@"/"]) {
    preparedStr = _url.path;
  } else {
    preparedStr = _url.lastPathComponent;
  }

  _score = rank_string(candidate, preparedStr);
}

#pragma mark NSObject
- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.score=%f", self.score];
  [description appendFormat:@", self.url=%@", self.url];
  [description appendString:@">"];
  return description;
}

@end
