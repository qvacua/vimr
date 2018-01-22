/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "ThreadWithBlock.h"

@interface BlockHolder: NSObject

- (instancetype)initWithBlock:(ThreadInitBlock)block;
- (void)blockInit:(id)sender;

@end

@implementation BlockHolder {
  ThreadInitBlock _block;
}

- (instancetype)initWithBlock:(ThreadInitBlock)block {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _block = block;
  return self;
}

- (void)blockInit:(id)sender {
  _block(sender);
}

@end


@implementation ThreadWithBlock

- (instancetype)initWithThreadInitBlock:(ThreadInitBlock)block {
  BlockHolder *blockHolder = [[BlockHolder alloc] initWithBlock:block];
  self = [super initWithTarget:blockHolder selector:@selector(blockInit:) object:nil];
  if (self == nil) {
    return nil;
  }

  return self;
}

@end