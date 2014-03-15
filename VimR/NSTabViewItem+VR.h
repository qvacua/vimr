/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import <Cocoa/Cocoa.h>


@class VRWorkspace;


@interface NSTabViewItem (VR)

@property (weak) VRWorkspace *associatedDocument;

@end
