/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

@protocol Session

@required

@property CFTimeInterval timeout;
@property (nonatomic, copy, nullable) void (^dataCallback)(NSData * _Nonnull);

@property (readonly, getter=isRunning) bool running;

- (NSError * _Nullable)connectAndRun;
- (void)disconnectAndStop;
- (CFSocketError)writeData:(NSData * _Nonnull)data;

@end

@interface UnixDomainSocketConnection : NSObject <Session>

@property CFTimeInterval timeout;
@property (nonatomic, nonnull) CFSocketRef socket;
@property (nonatomic, copy, nullable) void (^dataCallback)(NSData * _Nonnull);

- (instancetype _Nullable)initWithPath:(NSString * _Nonnull)path;

- (NSError * _Nullable)connectAndRun;
- (void)disconnectAndStop;
- (CFSocketError)writeData:(NSData * _Nonnull)data;

@end
