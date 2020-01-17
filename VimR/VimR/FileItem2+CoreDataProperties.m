//
//  FileItem2+CoreDataProperties.m
//  VimR
//
//  Created by Tae Won Ha on 17.01.20.
//  Copyright © 2020 Tae Won Ha. All rights reserved.
//
//

#import "FileItem2+CoreDataProperties.h"

@implementation FileItem2 (CoreDataProperties)

+ (NSFetchRequest<FileItem2 *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"FileItem2"];
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
