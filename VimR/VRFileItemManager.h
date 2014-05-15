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

@property (weak) NSFileManager *fileManager;
@property (weak) NSNotificationCenter *notificationCenter;
@property (readonly) NSArray *registeredUrls;
@property (readonly) NSArray *fileItemsOfTargetUrl;

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
- (NSString *)nameOfItem:(id)item;
- (NSURL *)urlForItem:(id)item;

- (void)registerUrl:(NSURL *)url;
- (void)resetTargetUrl;
- (BOOL)setTargetUrl:(NSURL *)url;
- (void)unregisterUrl:(NSURL *)url;
- (void)cleanUp;
- (BOOL)fileItemOperationPending;
- (void)pause;
- (void)resume;

// TODO: for debug only!
- (NSUInteger)operationCount;

#pragma mark NSObject
- (id)init;

@end
