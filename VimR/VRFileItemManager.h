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
@property (readonly) NSSet *registeredUrls;

#pragma mark Public
- (VRFileItem *)fileItemForUrl:(NSURL *)url;
- (void)registerUrl:(NSURL *)url;
- (void)cleanUp;

#pragma mark NSObject
- (id)init;

@end
