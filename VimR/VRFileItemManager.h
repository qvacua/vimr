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
- (void)registerUrl:(NSURL *)url;
- (void)resetTargetUrl;
- (BOOL)setTargetUrl:(NSURL *)url;
- (void)unregisterUrl:(NSURL *)url;
- (void)cleanUp;
- (void)pause;
- (void)resume;
- (BOOL)fileItemOperationPending;

// TODO: for debug only!
- (NSUInteger)operationCount;

#pragma mark NSObject
- (id)init;

@end
