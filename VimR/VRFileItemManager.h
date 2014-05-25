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

@property (nonatomic, weak) NSWorkspace *workspace;
@property (nonatomic, weak) NSFileManager *fileManager;
@property (nonatomic, weak) NSNotificationCenter *notificationCenter;

@property (nonatomic, readonly) NSArray *registeredUrls;
@property (nonatomic, readonly) NSArray *urlsOfTargetUrl;

#pragma mark Public
/**
* Synchronously caches the direct descendants of item.
*/
- (NSArray *)childrenOfItem:(id)item;
- (id)itemForUrl:(NSURL *)url;
- (BOOL)isItemDir:(id)item;
- (BOOL)isItemHidden:(id)item;
- (NSString *)nameOfItem:(id)item;
- (NSURL *)urlForItem:(id)item;

- (NSImage *)iconForUrl:(NSURL *)url;

- (void)registerUrl:(NSURL *)url;
- (void)unregisterUrl:(NSURL *)url;

- (BOOL)setTargetUrl:(NSURL *)url;
- (void)resetTargetUrl;

- (void)cleanUp;

- (void)pauseFileItemOperations;
- (void)resumeFileItemOperations;

- (BOOL)fileItemOperationPending;
- (void)suspendFurtherCacheOperations;
- (void)resumeFurtherCacheOperations;
- (void)waitTillFileItemOperationsFinished;

#pragma mark NSObject
- (id)init;

@end
