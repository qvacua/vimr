/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>
#import "VRUserDefaults.h"


@interface VRNode : NSObject

@property (nonatomic) NSURL *url;
@property (nonatomic) id item;
@property (nonatomic) NSString *name;
@property (nonatomic) NSArray *children;
@property (nonatomic, getter=isDir) BOOL dir;
@property (nonatomic, getter=isHidden) BOOL hidden;

- (NSString *)description;

@end


@interface VRFileBrowserOutlineView : NSOutlineView

- (id)selectedItem;
- (void)openInMode:(VROpenMode)mode;

@end
