/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "NSURL+VR.h"


NSString *const qGetResourceValueIsDirException = @"qGetResourceValueIsDir";

@implementation NSURL (VR)

- (BOOL)isDirectory {
  if (!self.isFileURL) {
    @throw [NSException exceptionWithName:qGetResourceValueIsDirException
                                   reason:@"The URL is not a file URL"
                                 userInfo:nil];
  }

  NSNumber *isDir = nil;
  NSError *error = nil;
  BOOL success = [self getResourceValue:&isDir forKey:NSURLIsDirectoryKey error:&error];

  if (success) {
    return isDir.boolValue;
  }

  @throw [NSException exceptionWithName:qGetResourceValueIsDirException
                                 reason:@"There was an error getting NSURLIsDirectoryKey"
                               userInfo:@{@"error" : error}];
}

@end
