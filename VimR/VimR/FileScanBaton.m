/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "FileScanBaton.h"
#import "util.h"
#import "FoundationCommons.h"

#ifdef DEBUG
FILE *out_fd;
static dispatch_once_t debugToken;
#endif

@implementation FileScanBaton {
  NSURL *_baseUrl;

  scandir_baton_t *_baton;

  const char *_basePathCstr;
  const char *_pathStartCstr;
}

static const char *cfstr_to_cstr_copy(CFStringRef cfstr);
static void load_global_gitignores(ignores *ig);

- (bool)test:(NSURL *_Nonnull)url {
  struct dirent dirent = url.fakeDirent;
  return (bool) filename_filter(_baton->path_start, &dirent, _baton);
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl {
#ifdef DEBUG
  dispatch_once(&debugToken, ^{
    out_fd = fopen("/Users/hat/Downloads/scan.log", "w");
    set_log_level(LOG_LEVEL_DEBUG);
  });
#endif

  self = [super init];
  if (self == nil) {return nil;}

  _baseUrl = baseUrl;
  _url = baseUrl;
  _pathStart = @".";

  _ig = init_ignore([FileScanBaton stubBatonWithGlobalGitignores].ig, "", 0);

  [self initScanDirBaton];
  [self loadVcsIgnores];

  return self;
}

- (instancetype)initWithParent:(FileScanBaton *)parent url:(NSURL *)url {
  self = [super init];
  if (self == nil) {return nil;}

  _baseUrl = parent.url;
  _url = url;
  _pathStart = [parent.pathStart stringByAppendingFormat:@"/%@", url.lastPathComponent];

  const char *dirname = [url.lastPathComponent cStringUsingEncoding:NSUTF8StringEncoding];
  _ig = init_ignore(parent.ig, dirname, strlen(dirname));

  [self initScanDirBaton];
  [self loadVcsIgnores];

  return self;
}

- (void)initScanDirBaton {
  _basePathCstr = (char *) cfstr_to_cstr_copy((__bridge CFStringRef) _baseUrl.path);
  _pathStartCstr = (char *) cfstr_to_cstr_copy((__bridge CFStringRef) _pathStart);

  _baton = malloc(sizeof(scandir_baton_t));
  _baton->ig = _ig;
  _baton->base_path = _basePathCstr;
  _baton->base_path_len = strlen(_basePathCstr);
  _baton->path_start = _pathStartCstr;
}

- (void)loadVcsIgnores {
  const char *ignoreFile = NULL;
  for (int i = 0; (ignore_pattern_files[i] != NULL); i++) {
    ignoreFile = ignore_pattern_files[i];

    char *dirFullPath = NULL;
    ag_asprintf(
        &dirFullPath,
        "%s/%s",
        [_url.path cStringUsingEncoding:NSUTF8StringEncoding],
        ignoreFile
    );
    load_ignore_patterns(_ig, dirFullPath);

    free(dirFullPath);
    dirFullPath = NULL;
  }
}

- (void)dealloc {
  cleanup_ignore(_ig);
  free(_baton);

  free((void *) _basePathCstr);
  free((void *) _pathStartCstr);
}

+ (instancetype)stubBatonWithGlobalGitignores {
  static FileScanBaton *sharedStub = nil;

  static dispatch_once_t singletonToken;
  dispatch_once(&singletonToken, ^{
    sharedStub = [[FileScanBaton alloc] initAsStub];
  });

  return sharedStub;
}

- (instancetype)initAsStub {
  self = [super init];
  if (self == nil) {return nil;}

  _baseUrl = [NSURL fileURLWithPath:@"~"];
  _url = _baseUrl;
  _pathStart = @".";

  _ig = init_ignore(NULL, "", 0);

  [self initScanDirBaton];
  load_global_gitignores(_ig);

  return self;
}

static const char *cfstr_to_cstr_copy(CFStringRef cfstr) {
  CFIndex out_len = 0;
  CFRange whole_range = CFRangeMake(0, CFStringGetLength(cfstr));
  CFIndex converted = CFStringGetBytes(
      cfstr,
      whole_range,
      kCFStringEncodingUTF8,
      0,
      false,
      NULL,
      0,
      &out_len
  );

  if (converted == 0 || out_len == 0) {return NULL;}

  char *result = malloc((size_t) (out_len + 1));
  converted = CFStringGetBytes(
      cfstr,
      whole_range,
      kCFStringEncodingUTF8,
      0,
      false,
      (UInt8 *) result,
      out_len,
      NULL
  );

  if (converted == 0) {
    free(result);
    return NULL;
  }

  result[out_len] = NULL;
  return result;
}

// From the_silver_searcher/options.c
static void load_global_gitignores(ignores *ig) {
  const char *home_dir = getenv("HOME");

  FILE *gitconfig_file = NULL;
  size_t buf_len = 0;
  char *gitconfig_res = NULL;
  gitconfig_file = popen("git config -z --path --get core.excludesfile 2>/dev/null", "r");
  if (gitconfig_file != NULL) {
    do {
      gitconfig_res = ag_realloc(gitconfig_res, buf_len + 65);
      buf_len += fread(gitconfig_res + buf_len, 1, 64, gitconfig_file);
    } while (!feof(gitconfig_file) && buf_len > 0 && buf_len % 64 == 0);
    gitconfig_res[buf_len] = '\0';
    if (buf_len == 0) {
      free(gitconfig_res);
      const char *config_home = getenv("XDG_CONFIG_HOME");
      if (config_home) {
        ag_asprintf(&gitconfig_res, "%s/%s", config_home, "git/ignore");
      } else {
        ag_asprintf(&gitconfig_res, "%s/%s", home_dir, ".config/git/ignore");
      }
    }
    log_debug("global core.excludesfile: %s", gitconfig_res);
    load_ignore_patterns(ig, gitconfig_res);
    free(gitconfig_res);
    pclose(gitconfig_file);
  }
}

@end

