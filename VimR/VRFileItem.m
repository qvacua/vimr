/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRFileItem.h"
#import "VRUtils.h"
#import "NSURL+VR.h"


@implementation VRFileItem

#pragma mark Public
- (instancetype)initWithUrl:(NSURL *)url {
  self = [super init];
  RETURN_NIL_WHEN_NOT_SELF;

  _url = url;
  _dir = url.isDirectory;
  _hidden = url.isHidden;
  _shouldCacheChildren = YES;
  _isCachingChildren = NO;

  if (_dir) {
    _children = [[NSMutableArray alloc] initWithCapacity:20];
  }

  return self;
}

- (BOOL)isEqualToItem:(VRFileItem *)item {
  if (self == item)
    return YES;
  if (item == nil)
    return NO;
  if (self.url != item.url && ![self.url isEqual:item.url])
    return NO;
  return YES;
}

#pragma mark NSObject
- (NSUInteger)hash {
  return [self.url hash];
}

- (BOOL)isEqual:(id)other {
  if (other == self)
    return YES;
  if (!other || ![[other class] isEqual:[self class]])
    return NO;

  return [self isEqualToItem:other];
}

- (NSString *)description {
  NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
  [description appendFormat:@"self.url=%@", self.url];
  [description appendString:@">"];
  return description;
}

@end
