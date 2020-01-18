/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "ignore.h"
#import "scandir.h"


@interface FileScanBaton : NSObject

@property(readonly, nonnull) ignores *ig;

@property(readonly, nonnull) NSString *pathStart;
@property(readonly, nonnull) NSURL *url;

- (bool)test:(NSURL * _Nonnull)url;

- (instancetype _Nonnull)initWithBaseUrl:(NSURL *_Nonnull)baseUrl;
- (instancetype _Nonnull)initWithParent:(FileScanBaton *_Nonnull)parent url:(NSURL *_Nonnull)url;

@end
