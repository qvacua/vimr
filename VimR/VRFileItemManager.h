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


extern NSString *const qChunkOfNewFileItemsAddedEvent;


@class VRFileItem;


@interface VRFileItemManager : NSObject <TBBean>

@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;

@property (nonatomic, readonly) NSArray *registeredUrls;
@property (nonatomic, readonly) NSArray *fileItemsOfTargetUrl;

#pragma mark Public
/**
* Synchronously caches the direct descendants of url
*/
- (NSArray *)childrenOfRootUrl:(NSURL *)rootUrl;
/**
* Synchronously caches the direct descendants of item.
*/
- (NSArray *)childrenOfItem:(id)item;
- (BOOL)isItemDir:(id)item;
- (BOOL)isItemHidden:(id)item;
- (NSString *)nameOfItem:(id)item;
- (NSURL *)urlForItem:(id)item;

- (void)registerUrl:(NSURL *)url;
- (void)resetTargetUrl;
- (BOOL)setTargetUrl:(NSURL *)url;
- (void)unregisterUrl:(NSURL *)url;
- (void)cleanUp;
- (BOOL)fileItemOperationPending;
- (void)suspendFurtherCacheOperations;
- (void)resumeFurtherCacheOperations;

#pragma mark NSObject
- (id)init;

@end
