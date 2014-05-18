/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@class VRFileItem;


@interface VRCachedFileItemRecord : NSObject

@property (nonatomic) VRFileItem *fileItem;
@property (nonatomic, readonly) NSUInteger countOfConsumer;

#pragma mark Public
- (instancetype)initWithFileItem:(VRFileItem *)fileItem;
- (void)incrementConsumer;
- (void)decrementConsumer;

@end
