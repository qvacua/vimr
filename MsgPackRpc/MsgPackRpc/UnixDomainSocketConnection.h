/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

@protocol Session

@required

@property CFTimeInterval timeout;
@property (nonatomic, copy, nullable) void (^dataCallback)(NSData * __nonnull);

@property (readonly, getter=isRunning) bool running;

- (void)connectAndRun;
- (void)disconnectAndStop;
- (CFSocketError)writeData:(NSData * __nonnull)data;

@end

@interface UnixDomainSocketConnection : NSObject <Session>

@property CFTimeInterval timeout;
@property (nonatomic, nonnull) CFSocketRef socket;
@property (nonatomic, copy, nullable) void (^dataCallback)(NSData * __nonnull);

- (instancetype __nullable)initWithPath:(NSString * __nonnull)path;

- (void)connectAndRun;
- (void)disconnectAndStop;
- (CFSocketError)writeData:(NSData * __nonnull)data;

@end
