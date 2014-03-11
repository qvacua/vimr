/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@class VRDocument;


@interface NSTabViewItem (VR)

@property (weak) VRDocument *associatedDocument;

@end
