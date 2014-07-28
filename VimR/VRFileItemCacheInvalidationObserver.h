/**
* Tae Won Ha — @hataewon
*
* http://taewon.de
* http://qvacua.com
*
* See LICENSE
*/

#import <Foundation/Foundation.h>


@protocol VRFileItemCacheInvalidationObserver

@required
- (void)registerFileItemCacheInvalidationObservation;
- (void)removeFileItemCacheInvalidationObservation;

@end
