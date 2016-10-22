/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NeoVimBuffer : NSObject <NSCoding>

@property (nonatomic, readonly) NSInteger handle;
@property (nonatomic, retain, nullable) NSString *fileName;
@property (nonatomic, readonly) bool isDirty;
@property (nonatomic, readonly) bool isCurrent;
@property (nonatomic, readonly) bool isTransient;

- (instancetype)initWithHandle:(NSInteger)handle
                      fileName:(NSString * _Nullable)fileName
                         dirty:(bool)dirty
                       current:(bool)current;

- (instancetype)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

- (NSString *)description;

@end

NS_ASSUME_NONNULL_END
