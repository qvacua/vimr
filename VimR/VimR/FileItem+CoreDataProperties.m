//
//  FileItem+CoreDataProperties.m
//  VimR
//
//  Created by Tae Won Ha on 18.01.20.
//  Copyright © 2020 Tae Won Ha. All rights reserved.
//
//

#import "FileItem+CoreDataProperties.h"

@implementation FileItem (CoreDataProperties)

+ (NSFetchRequest<FileItem *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"FileItem"];
}

@dynamic direntType;
@dynamic isHidden;
@dynamic isPackage;
@dynamic needsScanChildren;
@dynamic pathStart;
@dynamic url;
@dynamic children;
@dynamic parent;

@end
