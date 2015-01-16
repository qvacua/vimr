/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>
#import "VROperation.h"


extern NSString *const qFilterItemsOperationSearchStringKey;
extern NSString *const qFilterItemsOperationFilteredItemsKey;
extern NSString *const qFilterItemsOperationItemTableViewKey;
extern NSString *const qOpenQuicklyIgnorePatternsKey;
extern const NSUInteger qMaximumNumberOfFilterResult;


@class VROpenQuicklyWindowController;


@interface VRFilterItemsOperation : VROperation

#pragma mark Public
- (instancetype)initWithDict:(NSDictionary *)dict;

#pragma mark NSOperation
- (void)main;

@end
