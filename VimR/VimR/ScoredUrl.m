//
// Created by Tae Won Ha on 05.01.20.
// Copyright (c) 2020 Tae Won Ha. All rights reserved.
//

#import "ScoredUrl.h"


@implementation ScoredUrl {
}

- (BOOL)isEqual:(id)other {
  if (other == self)
    return YES;
  if (!other || ![[other class] isEqual:[self class]])
    return NO;

  return [self isEqualToUrl:other];
}

- (BOOL)isEqualToUrl:(ScoredUrl *)url {
  if (self == url)
    return YES;
  if (url == nil)
    return NO;
  if (self.url != url.url && ![self.url isEqual:url.url])
    return NO;
  if (self.score != url.score)
    return NO;
  return YES;
}

- (NSUInteger)hash {
  NSUInteger hash = [self.url hash];
  hash = hash * 31u + self.score;
  return hash;
}

- (NSString *)description {
  NSMutableString *description
      = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.url=%@", self.url.path];
  [description appendFormat:@", self.score=%li", self.score];
  [description appendString:@">"];
  return description;
}

- (instancetype)initWithUrl:(NSURL *)url score:(NSInteger)score {
  self = [super init];
  if (!self) {return nil;}

  _url = url;
  _score = score;

  return self;
}

+ (instancetype)urlWithUrl:(NSURL *)url score:(NSInteger)score {
  return [[self alloc] initWithUrl:url score:score];
}

@end
