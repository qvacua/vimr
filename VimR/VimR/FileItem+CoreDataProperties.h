//
//  FileItem+CoreDataProperties.h
//  VimR
//
//  Created by Tae Won Ha on 18.01.20.
//  Copyright © 2020 Tae Won Ha. All rights reserved.
//
//

#import "FileItem+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface FileItem (CoreDataProperties)

+ (NSFetchRequest<FileItem *> *)fetchRequest;

@property (nonatomic) int16_t direntType;
@property (nonatomic) BOOL isHidden;
@property (nonatomic) BOOL isPackage;
@property (nonatomic) BOOL needsScanChildren;
@property (nullable, nonatomic, copy) NSString *pathStart;
@property (nullable, nonatomic, copy) NSURL *url;
@property (nullable, nonatomic, retain) NSSet<FileItem *> *children;
@property (nullable, nonatomic, retain) FileItem *parent;

@end

@interface FileItem (CoreDataGeneratedAccessors)

- (void)addChildrenObject:(FileItem *)value;
- (void)removeChildrenObject:(FileItem *)value;
- (void)addChildren:(NSSet<FileItem *> *)values;
- (void)removeChildren:(NSSet<FileItem *> *)values;

@end

NS_ASSUME_NONNULL_END
