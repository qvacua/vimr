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


@implementation VRUtilsTest {
  NSString *rsrcPath;
}

- (void)setUp {
  rsrcPath = [[NSBundle bundleForClass:[self class]] resourcePath];
}

- (void)testCommonParentUrl {
  NSURL *url1 = [NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1/level-1-file-1"]];
  NSURL *url2 = [NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1/level-2-a"]];
  NSURL *url3 = [NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1/level-2-b/level-2-b-file-1"]];

  NSURL *parent = common_parent_url(@[url1, url2, url3]);
  assertThat(parent, is([NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1"]]));
}

- (void)testCommonParentUrlWithOneDir {
  NSURL *parent = common_parent_url(@[[NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1"]]]);
  assertThat(parent, is([NSURL fileURLWithPath:[rsrcPath stringByAppendingPathComponent:@"level-1"]]));
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

- (void)testBlank {
  assertThat(@(blank(nil)), isYes);
  assertThat(@(blank(@"")), isYes);

  assertThat(@(blank(@"str")), isNo);
}

- (void)testPathMatchesShellPattern {
  assertThat(@(path_matches_shell_pattern("*/.git", @"/a/b/.git/c/d")), isYes);
  assertThat(@(path_matches_shell_pattern("*/.git", @"/a/b/git/c/d")), isNo);
  assertThat(@(path_matches_shell_pattern(".git", @"/a/b/.git/c/d")), isNo);

  assertThat(@(path_matches_shell_pattern(".gitignore", @"/a/b/.gitignore")), isYes);
  assertThat(@(path_matches_shell_pattern(".gitignore", @".gitignore")), isYes);
  assertThat(@(path_matches_shell_pattern(".gitignore", @"/a/b/.gitconfig")), isNo);
  assertThat(@(path_matches_shell_pattern(".gitignore", @"dgitconfig")), isNo);

  assertThat(@(path_matches_shell_pattern("*/.git/*.config", @"/a/b/.git/branch.config")), isYes);
  assertThat(@(path_matches_shell_pattern("*/.git/*.config", @"/a/b/.git/c/branch.config")), isYes);
  assertThat(@(path_matches_shell_pattern("*/.git/*.config", @"/a/b/.git/c/branch.config/test")), isYes);

  assertThat(@(path_matches_shell_pattern("*.iml", @"/a/b/c/test.iml")), isYes);
  assertThat(@(path_matches_shell_pattern("*.iml", @"/a/b/c/test.iml/d/e")), isNo);
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

- (void)testDirRelativeToFile {
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
