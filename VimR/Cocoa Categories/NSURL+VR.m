/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "NSURL+VR.h"


NSString *const qUrlGetResourceValueIsDirExceptionName = @"qGetResourceValueIsDirException";
NSString *const qUrlNoParentExceptionName = @"qNoParentException";


@implementation NSURL (VR)

- (BOOL)isHidden {
  if (!self.isFileURL) {
    @throw [NSException exceptionWithName:qUrlGetResourceValueIsDirExceptionName
                                   reason:@"The URL is not a file URL"
                                 userInfo:nil];
  }

  NSNumber *isHidden = nil;
  NSError *error = nil;
  BOOL success = [self getResourceValue:&isHidden forKey:NSURLIsHiddenKey error:&error];

  if (success) {
    return isHidden.boolValue;
  }

  @throw [NSException exceptionWithName:qUrlGetResourceValueIsDirExceptionName
                                 reason:@"There was an error getting NSURLIsHiddenKey"
                               userInfo:@{@"error" : error}];
}

- (BOOL)isDirectory {
  if (!self.isFileURL) {
    @throw [NSException exceptionWithName:qUrlGetResourceValueIsDirExceptionName
                                   reason:@"The URL is not a file URL"
                                 userInfo:nil];
  }

  NSNumber *isDir = nil;
  NSError *error = nil;
  BOOL success = [self getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:&error];

  if (success) {
    return isDir.boolValue;
  }

  @throw [NSException exceptionWithName:qUrlGetResourceValueIsDirExceptionName
                                 reason:@"There was an error getting NSURLIsDirectoryKey"
                               userInfo:@{@"error" : error}];
}

- (NSString *)parentName {
  if ([self.path isEqualToString:@"/"]) {
    @throw [NSException exceptionWithName:qUrlNoParentExceptionName reason:@"The root folder cannot have a parent"
                                 userInfo:nil];
  }

  return self.URLByDeletingLastPathComponent.lastPathComponent;
}

- (BOOL)isParentToUrl:(NSURL *)url {
  NSString *path = self.path;
  NSUInteger pathLength = path.length;

  NSString *targetPath = url.path;
  if (pathLength > targetPath.length) {
    return NO;
  }

  return [[targetPath substringToIndex:pathLength] isEqualToString:path];
}

@end
