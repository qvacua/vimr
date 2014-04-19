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


@interface VRFileItemManager : NSObject <TBBean>

@property (weak) NSFileManager *fileManager;
@property (readonly) NSSet *monitoredUrls;

#pragma mark Public
- (void)monitorUrl:(NSURL *)url;

#pragma mark NSObject
- (id)init;

@end
