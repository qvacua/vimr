/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@interface VRFileItem : NSObject

@property (copy) NSURL *url;
@property (readonly) NSString *displayName;
@property (readonly) NSArray *children;

#pragma mark Public
- (instancetype)initWithUrl:(NSURL *)url;

@end
