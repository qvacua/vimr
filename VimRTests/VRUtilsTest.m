/**
 * Tae Won Ha — @hataewon
 *
 * http://taewon.de
 * http://qvacua.com
 *
 * See LICENSE
 */

#import "VRBaseTestCase.h"
#import "VRUtils.h"


@interface VRUtilsTest : VRBaseTestCase
@end


@implementation VRUtilsTest

- (void)testCommonParentUrl {
  NSURL *parent = common_parent_url(@[
      [NSURL fileURLWithPath:@"/a/b/c/d/e.txt"],
      [NSURL fileURLWithPath:@"/a/b/c/d/1/2/3/o.txt"],
      [NSURL fileURLWithPath:@"/a/b/c/ae.txt"],
      [NSURL fileURLWithPath:@"/a/b/c/d/3.txt"],
  ]);

  assertThat(parent.path, is(@"/a/b/c"));
}

- (void)testUrlsFromPaths {
  NSArray *paths = @[
      @"/System/Library",
      @"/Library",
  ];

  assertThat(urls_from_paths(paths), consistsOfInAnyOrder(
      [NSURL fileURLWithPath:@"/System/Library"],
      [NSURL fileURLWithPath:@"/Library"]
  ));
}

@end


#pragma mark VRFileManagerStub


@interface VRFileManagerStub : NSFileManager

@end


@implementation VRFileManagerStub {
  NSMutableDictionary *stubbedPaths;
}

- (instancetype)init {
  if ((self = [super init])) {
    stubbedPaths = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)stubPath:(NSString *)path isDirectory:(BOOL)isDirectory {
  stubbedPaths[path] = @(isDirectory);
}

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory {
  for (NSString *stubbedPath in stubbedPaths) {
    if ([path isEqualToString:stubbedPath]) {
      *isDirectory = [stubbedPaths[stubbedPath] boolValue];
      return YES;
    }
  }
  return NO;
}

@end


#pragma mark VRUtilsResolvePathTest


@interface VRUtilsResolvePathTest : VRBaseTestCase

@end


@implementation VRUtilsResolvePathTest {
  VRFileManagerStub *fileManager;
  BOOL isDirectory;
}

- (void)setUp {
  fileManager = [[VRFileManagerStub alloc] init];
}

- (NSString *)resolvePath:(NSString *)path relativeToPath:(NSString *)relativeToPath sibling:(BOOL)sibling {
  return VRResolvePathRelativeToPathWithFileManager(path, relativeToPath, sibling, fileManager);
}

- (NSString *)resolvePath:(NSString *)path relativeToPath:(NSString *)relativeToPath {
  return [self resolvePath:path relativeToPath:relativeToPath sibling:NO];
}

- (void)testAbsolutePath {
  NSString *path = [self resolvePath:@"/absolute/path" relativeToPath:@"/tmp/file"];
  assertThat(path, is(@"/absolute/path"));
}

- (void)testTildePath {
  NSString *path = [self resolvePath:@"~/absolute/path" relativeToPath:@"/tmp/file"];
  assertThat(path, isNot(anyOf(containsString(@"~"), containsString(@"tmp"), containsString(@"file"), nil)));
}

- (void)testDoesNotExistRelativeToFile {
  [fileManager stubPath:@"/tmp/file" isDirectory:NO];
  
  NSString *path = [self resolvePath:@"file2" relativeToPath:@"/tmp/file"];
  assertThat(path, is(@"/tmp/file2"));
}

- (void)testDoesNotExistRelativeToDir {
  [fileManager stubPath:@"/tmp/dir" isDirectory:YES];
  
  NSString *path = [self resolvePath:@"file" relativeToPath:@"/tmp/dir"];
  assertThat(path, is(@"/tmp/dir/file"));
}

- (void)testDoesNotExistRelativeToDirWithSiblingHint {
  [fileManager stubPath:@"/tmp/dir" isDirectory:YES];
  
  NSString *path = [self resolvePath:@"file" relativeToPath:@"/tmp/dir" sibling:YES];
  assertThat(path, is(@"/tmp/file"));
}

- (void)testFileRelativeToFile {
  [fileManager stubPath:@"/tmp/file" isDirectory:NO];
  [fileManager stubPath:@"/tmp/file2" isDirectory:NO];
  
  NSString *path = [self resolvePath:@"file2" relativeToPath:@"/tmp/file"];
  assertThat(path, is(@"/tmp/file2"));
}

- (void)testFileRelativeToDir {
  [fileManager stubPath:@"/tmp/dir" isDirectory:YES];
  [fileManager stubPath:@"/tmp/dir/file" isDirectory:NO];
  
  NSString *path = [self resolvePath:@"file" relativeToPath:@"/tmp/dir"];
  assertThat(path, is(@"/tmp/dir/file"));
}

- (void)testDirRelativeToFile  {
  [fileManager stubPath:@"/tmp/file" isDirectory:NO];
  [fileManager stubPath:@"/tmp/dir" isDirectory:YES];
  
  NSString *path = [self resolvePath:@"dir" relativeToPath:@"/tmp/file"];
  assertThat(path, is(@"/tmp/dir/file"));
}

- (void)testDirRelativeToDir {
  [fileManager stubPath:@"/tmp/dir" isDirectory:YES];
  [fileManager stubPath:@"/tmp/dir2" isDirectory:YES];
  
  NSString *path = [self resolvePath:@"dir2" relativeToPath:@"/tmp/dir"];
  assertThat(path, is(@"/tmp/dir/dir2"));
}

@end
