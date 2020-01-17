//
//  FileItem2+CoreDataProperties.h
//  VimR
//
//  Created by Tae Won Ha on 17.01.20.
//  Copyright © 2020 Tae Won Ha. All rights reserved.
//
//

#import "FileItem2+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface FileItem2 (CoreDataProperties)

+ (NSFetchRequest<FileItem2 *> *)fetchRequest;

@property (nonatomic) int16_t direntType;
@property (nonatomic) BOOL isHidden;
@property (nonatomic) BOOL isPackage;
@property (nonatomic) BOOL needsScanChildren;
@property (nullable, nonatomic, copy) NSString *pathStart;
@property (nullable, nonatomic, copy) NSURL *url;
@property (nullable, nonatomic, retain) NSSet<FileItem2 *> *children;
@property (nullable, nonatomic, retain) FileItem2 *parent;

@end

@interface FileItem2 (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(FileItem2 *)value;
- (void)removeChildrenObject:(FileItem2 *)value;
- (void)addChildren:(NSSet<FileItem2 *> *)values;
- (void)removeChildren:(NSSet<FileItem2 *> *)values;

@end

NS_ASSUME_NONNULL_END
