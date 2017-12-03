/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;


@interface DataWrapper : NSObject

@property (strong) NSData *data;
@property (getter=isDataReady) bool dataReady;

@end
