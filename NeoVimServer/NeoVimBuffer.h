/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NeoVimBuffer : NSObject <NSCoding>

@property (nonatomic, readonly) NSUInteger handle;
@property (nonatomic, retain, nullable) NSString *fileName;
@property (nonatomic, readonly, getter=isDirty) bool dirty;
@property (nonatomic, readonly, getter=isCurrent) bool current;
@property (nonatomic, readonly, getter=isTransient) bool transient;

- (instancetype)initWithHandle:(NSUInteger)handle
                      fileName:(NSString * _Nullable)fileName
                         dirty:(bool)dirty
                       current:(bool)current;

- (instancetype)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
