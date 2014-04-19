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


@implementation VRFileItem

- (NSString *)displayName {
    return self.url.lastPathComponent;
}

- (instancetype)initWithUrl:(NSURL *)url {
    self = [super init];
    RETURN_NIL_WHEN_NOT_SELF;

    _url = url;

    return self;
}

@end
