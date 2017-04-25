/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NeoVimBuffer : NSObject <NSCoding>

@property (nonatomic, readonly) NSInteger handle;
@property (nonatomic, readonly, nullable) NSURL *url;
/**
 * Only the file name
 */
@property (nonatomic, readonly, nullable) NSString *name;
@property (nonatomic, readonly) bool isReadOnly;
@property (nonatomic, readonly) bool isDirty;
@property (nonatomic, readonly) bool isCurrent;
@property (nonatomic, readonly) bool isTransient;

- (instancetype)initWithHandle:(NSInteger)handle
                 unescapedPath:(NSString *_Nullable)unescapedPath
                         dirty:(bool)dirty
                      readOnly:(bool)readOnly
                       current:(bool)current;

- (instancetype)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;

- (NSString *)description;
- (BOOL)isEqual:(id _Nullable)other;
- (BOOL)isEqualToBuffer:(NeoVimBuffer *)buffer;
- (NSUInteger)hash;

@end

NS_ASSUME_NONNULL_END

@interface NeoVimBuffer (Equality)

- (BOOL)isEqual:(id _Nullable)other;
- (BOOL)isEqualToBuffer:(NeoVimBuffer * _Nullable)buffer;
- (NSUInteger)hash;

@end
