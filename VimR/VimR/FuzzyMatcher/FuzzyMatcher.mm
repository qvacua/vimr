/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "FuzzyMatcher.h"
#import "fuzzy_match.hh"


@implementation FuzzyMatcher {
  ccls::FuzzyMatcher *_matcher;
}

- (NSInteger)maxPatternLength {
  return ccls::FuzzyMatcher::kMaxPat;
}

- (NSInteger)maxTextLength {
  return ccls::FuzzyMatcher::kMaxText;
}

- (NSInteger)minScore {
  return ccls::FuzzyMatcher::kMinScore;
}

- (instancetype)initWithPattern:(NSString *)pattern {
  self = [super init];
  if (!self) {return nil;}

  _matcher = new ccls::FuzzyMatcher([pattern cStringUsingEncoding:NSUTF8StringEncoding], 0);

  return self;
}

- (NSInteger)score:(NSString *)text {
  return _matcher->match([text cStringUsingEncoding:NSUTF8StringEncoding], false);
}

@end
