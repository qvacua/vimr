/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import <TBCacao/TBCacao.h>


@class VRFileItem;


@interface VRFileItemManager : NSObject <TBBean>

@property (weak) NSFileManager *fileManager;
@property (readonly) NSArray *registeredUrls;
@property (readonly) NSArray *fileItemsOfTargetUrl;

#pragma mark Public
- (void)unregisterUrl:(NSURL *)url;
- (BOOL)setTargetUrl:(NSURL *)url;
- (void)registerUrl:(NSURL *)url;
- (void)resetTargetUrl;
- (void)cleanUp;

#pragma mark NSObject
- (id)init;

@end
