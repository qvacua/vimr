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
@property (readonly, getter=isDir) BOOL dir;
@property (readonly) NSString *displayName;
@property (readonly) NSMutableArray *children;

#pragma mark Public
- (instancetype)initWithUrl:(NSURL *)url isDir:(BOOL)isDir;
- (BOOL)isEqualToItem:(VRFileItem *)item;

#pragma mark NSObject
- (BOOL)isEqual:(id)other;
- (NSUInteger)hash;
- (NSString *)description;

@end
