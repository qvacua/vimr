/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Foundation/Foundation.h>


extern NSString *const qFilterItemsOperationFileItemManagerKey;
extern NSString *const qFilterItemsOperationSearchStringKey;
extern NSString *const qFilterItemsOperationFilteredItemsKey;
extern NSString *const qFilterItemsOperationItemTableViewKey;
extern const NSUInteger qMaximumNumberOfFilterResult;

@class VROpenQuicklyWindowController;


@interface VRFilterItemsOperation : NSOperation

#pragma mark Public
- (instancetype)initWithDict:(NSDictionary *)dict;

#pragma mark NSOperation
- (void)main;

@end
