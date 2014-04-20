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

/**
* If YES, direct descendants are not in the children array yet, so they should be scanned.
* IF NO, direct descendants are there, but it is possible, that they still don't have their descendants yet.
*/
@property BOOL shouldCacheChildren;

/**
* If YES, direct descendants are being scanned.
* Even if NO, it is possible, that its children are scanning their descendants
*/
@property BOOL isCachingChildren;

#pragma mark Public
- (instancetype)initWithUrl:(NSURL *)url isDir:(BOOL)isDir;
- (BOOL)isEqualToItem:(VRFileItem *)item;

#pragma mark NSObject
- (BOOL)isEqual:(id)other;
- (NSUInteger)hash;
- (NSString *)description;

@end
