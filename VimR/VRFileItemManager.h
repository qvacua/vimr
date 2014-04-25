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
@property (readonly) NSSet *currentlyTraversedUrls;
@property (readonly) NSSet *currentlyCachingUrls;

#pragma mark Public
- (void)registerUrl:(NSURL *)url;
- (void)resetTargetUrl;
- (BOOL)setTargetUrl:(NSURL *)url;
- (void)unregisterUrl:(NSURL *)url;
- (void)cleanUp;

#pragma mark NSObject
- (id)init;

@end
