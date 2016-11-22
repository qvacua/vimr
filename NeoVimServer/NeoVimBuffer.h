/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NeoVimBuffer : NSObject <NSCoding>

@property (nonatomic, readonly) NSInteger handle;
/**
 * Full path
 */
@property (nonatomic, retain, nullable) NSString *fileName;
/**
 * Only the file name
 */
@property (nonatomic, readonly, nullable) NSString *name;
@property (nonatomic, readonly) bool isReadOnly;
@property (nonatomic, readonly) bool isDirty;
@property (nonatomic, readonly) bool isCurrent;
@property (nonatomic, readonly) bool isTransient;

- (instancetype)initWithHandle:(NSInteger)handle
                      fileName:(NSString * _Nullable)fileName
                         dirty:(bool)dirty
                      readOnly:(bool)readOnly
                       current:(bool)current;

- (instancetype)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

- (NSString *)description;

@end

NS_ASSUME_NONNULL_END

@interface NeoVimBuffer (Equality)

- (BOOL)isEqual:(id _Nullable)other;
- (BOOL)isEqualToBuffer:(NeoVimBuffer * _Nullable)buffer;
- (NSUInteger)hash;

@end
