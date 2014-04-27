/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "NSURL+VR.h"


NSString *const qUrlGetResourceValueIsDirException = @"qGetResourceValueIsDirException";
NSString *const qUrlNoParentException = @"qNoParentException";


@implementation NSURL (VR)

- (BOOL)isDirectory {
  if (!self.isFileURL) {
    @throw [NSException exceptionWithName:qUrlGetResourceValueIsDirException
                                   reason:@"The URL is not a file URL"
                                 userInfo:nil];
  }

  NSNumber *isDir = nil;
  NSError *error = nil;
  BOOL success = [self getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:&error];

  if (success) {
    return isDir.boolValue;
  }

  @throw [NSException exceptionWithName:qUrlGetResourceValueIsDirException
                                 reason:@"There was an error getting NSURLIsDirectoryKey"
                               userInfo:@{@"error" : error}];
}

- (NSString *)parentName {
  if ([self.path isEqualToString:@"/"]) {
    @throw [NSException exceptionWithName:qUrlNoParentException reason:@"The root folder cannot have a parent"
                                 userInfo:nil];
  }

  return self.URLByDeletingLastPathComponent.lastPathComponent;
}

@end
