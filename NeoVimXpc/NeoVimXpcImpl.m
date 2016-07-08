/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimXpcImpl.h"
#import "NeoVimUiBridgeProtocol.h"
#import "Logging.h"

// FileInfo and Boolean are #defined by Carbon and NeoVim: Since we don't need the Carbon versions of them, we rename
// them.
#define FileInfo CarbonFileInfo
#define Boolean CarbonBoolean

#import <nvim/vim.h>
#import <nvim/api/vim.h>
#import <nvim/ui.h>
#import <nvim/ui_bridge.h>
#import <nvim/event/signal.h>
#import <nvim/main.h>
#import <nvim/cursor.h>
#import <nvim/screen.h>


#define pun_type(t, x) (*((t *)(&x)))

typedef struct {
    UIBridgeData *bridge;
    Loop *loop;

    bool stop;

    // FIXME: dunno whether we need this: copied from tui.c
    bool cont_received;
    SignalWatcher cont_handle;
} XpcUiData;

// We declare nvim_main because it's not declared in any header files of neovim
extern int nvim_main(int argc, char **argv);

static unsigned int _default_foreground = qDefaultForeground;
static unsigned int _default_background = qDefaultBackground;
static unsigned int _default_special = qDefaultSpecial;

// The thread in which neovim's main runs
static uv_thread_t _nvim_thread;

// Condition variable used by the XPC's init to wait till our custom UI initialization is finished inside neovim
static bool _is_ui_launched = false;
static uv_mutex_t _mutex;
static uv_cond_t _condition;

static XpcUiData *_xpc_ui_data;
static id <NeoVimUiBridgeProtocol> _neo_vim_osx_ui;

static NSString *_marked_text = nil;

static int _marked_row = 0;
static int _marked_column = 0;

// for 하 -> hanja popup, Cocoa first inserts 하, then sets marked text, cf docs/notes-on-cocoa-text-input.md
static int _marked_delta = 0;

static int _put_row = -1;
static int _put_column = -1;

static NSString *_backspace = nil;

static dispatch_queue_t _queue;

static inline int screen_cursor_row() {
  return curwin->w_winrow + curwin->w_wrow;
}

static inline int screen_cursor_column() {
  return curwin->w_wincol + curwin->w_wcol;
}

// TODO: Is it possible to optimize away @autoreleasepool?
static inline void xpc_sync(void (^block)()) {
  dispatch_sync(_queue, ^{
    @autoreleasepool {
      block();
    }
  });
}

static void set_ui_size(UIBridgeData *bridge, int width, int height) {
  bridge->ui->width = width;
  bridge->ui->height = height;
  bridge->bridge.width = width;
  bridge->bridge.height = height;
}

static void sigcont_cb(SignalWatcher *watcher __unused, int signum __unused, void *data) {
  ((XpcUiData *) data)->cont_received = true;
}

static void osx_xpc_ui_scheduler(Event event, void *d) {
  UI *ui = d;
  XpcUiData *data = ui->data;
  loop_schedule(data->loop, event);
}

static void osx_xpc_ui_main(UIBridgeData *bridge, UI *ui) {
  Loop loop;
  loop_init(&loop, NULL);

  _xpc_ui_data = xcalloc(1, sizeof(XpcUiData));
  ui->data = _xpc_ui_data;
  _xpc_ui_data->bridge = bridge;
  _xpc_ui_data->loop = &loop;

  // FIXME: dunno whether we need this: copied from tui.c
  signal_watcher_init(_xpc_ui_data->loop, &_xpc_ui_data->cont_handle, _xpc_ui_data);
  signal_watcher_start(&_xpc_ui_data->cont_handle, sigcont_cb, SIGCONT);

  set_ui_size(bridge, 30, 15);

  _xpc_ui_data->stop = false;
  CONTINUE(bridge);

  uv_mutex_lock(&_mutex);
  _is_ui_launched = true;
  uv_cond_signal(&_condition);
  uv_mutex_unlock(&_mutex);

  while (!_xpc_ui_data->stop) {
    loop_poll_events(&loop, -1);
  }

  ui_bridge_stopped(bridge);
  loop_close(&loop);

  xfree(_xpc_ui_data);
  xfree(ui);
}

// FIXME: dunno whether we need this: copied from tui.c
static void suspend_event(void **argv) {
  UI *ui = argv[0];
  XpcUiData *data = ui->data;
  data->cont_received = false;

  kill(0, SIGTSTP);

  while (!data->cont_received) {
    // poll the event loop until SIGCONT is received
    loop_poll_events(data->loop, -1);
  }

  CONTINUE(data->bridge);
}

static void xpc_ui_resize(UI *ui __unused, int width, int height) {
  xpc_sync(^{
    [_neo_vim_osx_ui resizeToWidth:width height:height];
  });
}

static void xpc_ui_clear(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui clear];
  });
}

static void xpc_ui_eol_clear(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui eolClear];
  });
}

static void xpc_ui_cursor_goto(UI *ui __unused, int row, int col) {
  xpc_sync(^{
//    log4Debug("%d:%d", row, col);

    _put_row = row;
    _put_column = col;

    [_neo_vim_osx_ui gotoPosition:(Position) {.row = row, .column = col}
                     screenCursor:(Position) {.row = screen_cursor_row(), .column = screen_cursor_column()}
                     bufferCursor:(Position) {.row = curwin->w_cursor.lnum - 1, .column = curwin->w_cursor.col}];
  });
}

static void xpc_ui_update_menu(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui updateMenu];
  });
}

static void xpc_ui_busy_start(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui busyStart];
  });
}

static void xpc_ui_busy_stop(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui busyStop];
  });
}

static void xpc_ui_mouse_on(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui mouseOn];
  });
}

static void xpc_ui_mouse_off(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui mouseOff];
  });
}

static void xpc_ui_mode_change(UI *ui __unused, int mode) {
  xpc_sync(^{
    [_neo_vim_osx_ui modeChange:mode];
  });
}

static void xpc_ui_set_scroll_region(UI *ui __unused, int top, int bot, int left, int right) {
  xpc_sync(^{
    [_neo_vim_osx_ui setScrollRegionToTop:top bottom:bot left:left right:right];
  });
}

static void xpc_ui_scroll(UI *ui __unused, int count) {
  xpc_sync(^{
    [_neo_vim_osx_ui scroll:count];
  });
}

static void xpc_ui_highlight_set(UI *ui __unused, HlAttrs attrs) {
  xpc_sync(^{
    FontTrait trait = FontTraitNone;
    if (attrs.italic) {
      trait |= FontTraitItalic;
    }
    if (attrs.bold) {
      trait |= FontTraitBold;
    }
    if (attrs.underline) {
      trait |= FontTraitUnderline;
    }
    if (attrs.undercurl) {
      trait |= FontTraitUndercurl;
    }
    CellAttributes cellAttrs;
    cellAttrs.fontTrait = trait;

    unsigned int fg = attrs.foreground == -1 ? _default_foreground : pun_type(unsigned int, attrs.foreground);
    unsigned int bg = attrs.background == -1 ? _default_background : pun_type(unsigned int, attrs.background);

    cellAttrs.foreground = attrs.reverse ? bg : fg;
    cellAttrs.background = attrs.reverse ? fg : bg;
    cellAttrs.special = attrs.special == -1 ? _default_special : pun_type(unsigned int, attrs.special);

    [_neo_vim_osx_ui highlightSet:cellAttrs];
  });
}

static void xpc_ui_put(UI *ui __unused, uint8_t *str, size_t len) {
  xpc_sync(^{
    NSString *string = [[NSString alloc] initWithBytes:str length:len encoding:NSUTF8StringEncoding];
//    printf("%s", [string cStringUsingEncoding:NSUTF8StringEncoding]);

    if (_marked_text != nil && _marked_row == _put_row && _marked_column == _put_column) {
//      log4Debug("putting marked text: '%@'", string);
      [_neo_vim_osx_ui putMarkedText:string];
    } else if (_marked_text != nil && len == 0 && _marked_row == _put_row && _marked_column == _put_column - 1) {
//      log4Debug("putting marked text cuz zero");
      [_neo_vim_osx_ui putMarkedText:string];
    } else {
//      log4Debug("putting non-marked text: '%@'", string);
      [_neo_vim_osx_ui put:string];
    }

    _put_column += 1;
    [string release];
  });
}

static void xpc_ui_bell(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui bell];
  });
}

static void xpc_ui_visual_bell(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui visualBell];
  });
}

static void xpc_ui_flush(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui flush];
  });
}

static void xpc_ui_update_fg(UI *ui __unused, int fg) {
  xpc_sync(^{
    if (fg == -1) {
      [_neo_vim_osx_ui updateForeground:_default_foreground];
      return;
    }

    _default_foreground = pun_type(unsigned int, fg);
    [_neo_vim_osx_ui updateForeground:fg];
  });
}

static void xpc_ui_update_bg(UI *ui __unused, int bg) {
  xpc_sync(^{
    if (bg == -1) {
      [_neo_vim_osx_ui updateBackground:_default_background];
      return;
    }

    _default_background = pun_type(unsigned int, bg);
    [_neo_vim_osx_ui updateBackground:bg];
  });
}

static void xpc_ui_update_sp(UI *ui __unused, int sp) {
  xpc_sync(^{
    if (sp == -1) {
      [_neo_vim_osx_ui updateSpecial:_default_special];
      return;
    }

    _default_special = pun_type(unsigned int, sp);
    [_neo_vim_osx_ui updateSpecial:sp];
  });
}

static void xpc_ui_suspend(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui suspend];

    XpcUiData *data = ui->data;
    // FIXME: dunno whether we need this: copied from tui.c
    // kill(0, SIGTSTP) won't stop the UI thread, so we must poll for SIGCONT
    // before continuing. This is done in another callback to avoid
    // loop_poll_events recursion
    queue_put_event(data->loop->fast_events, event_create(1, suspend_event, 1, ui));
  });
}

static void xpc_ui_set_title(UI *ui __unused, char *title) {
  xpc_sync(^{
    NSString *string = [[NSString alloc] initWithCString:title encoding:NSUTF8StringEncoding];
    [_neo_vim_osx_ui setTitle:string];
    [string release];
  });
}

static void xpc_ui_set_icon(UI *ui __unused, char *icon) {
  xpc_sync(^{
    NSString *string = [[NSString alloc] initWithCString:icon encoding:NSUTF8StringEncoding];
    [_neo_vim_osx_ui setIcon:string];
    [string release];
  });
}

static void xpc_ui_stop(UI *ui __unused) {
  xpc_sync(^{
    [_neo_vim_osx_ui stop];

    XpcUiData *data = (XpcUiData *) ui->data;
    data->stop = true;
  });
}

static void run_neovim(void *arg __unused) {
  char *argv[1];
  argv[0] = "nvim";

  int returnCode = nvim_main(1, argv);

  log4Debug("neovim's main returned with code: %d", returnCode);
}

void custom_ui_start(void) {
  UI *ui = xcalloc(1, sizeof(UI));

  ui->rgb = true;
  ui->stop = xpc_ui_stop;
  ui->resize = xpc_ui_resize;
  ui->clear = xpc_ui_clear;
  ui->eol_clear = xpc_ui_eol_clear;
  ui->cursor_goto = xpc_ui_cursor_goto;
  ui->update_menu = xpc_ui_update_menu;
  ui->busy_start = xpc_ui_busy_start;
  ui->busy_stop = xpc_ui_busy_stop;
  ui->mouse_on = xpc_ui_mouse_on;
  ui->mouse_off = xpc_ui_mouse_off;
  ui->mode_change = xpc_ui_mode_change;
  ui->set_scroll_region = xpc_ui_set_scroll_region;
  ui->scroll = xpc_ui_scroll;
  ui->highlight_set = xpc_ui_highlight_set;
  ui->put = xpc_ui_put;
  ui->bell = xpc_ui_bell;
  ui->visual_bell = xpc_ui_visual_bell;
  ui->update_fg = xpc_ui_update_fg;
  ui->update_bg = xpc_ui_update_bg;
  ui->update_sp = xpc_ui_update_sp;
  ui->flush = xpc_ui_flush;
  ui->suspend = xpc_ui_suspend;
  ui->set_title = xpc_ui_set_title;
  ui->set_icon = xpc_ui_set_icon;

  ui_bridge_attach(ui, osx_xpc_ui_main, osx_xpc_ui_scheduler);
}

static void force_redraw(void **argv __unused) {
  must_redraw = CLEAR;
  update_screen(0);
}

static void refresh_ui(void **argv __unused) {
  ui_refresh();
}

// TODO: optimize away @autoreleasepool?
static void neovim_input(void **argv) {
  @autoreleasepool {
    NSString *input = (NSString *) argv[0];

    // FIXME: check the length of the consumed bytes by neovim and if not fully consumed, call vim_input again.
    vim_input((String) {
        .data = (char *) input.UTF8String,
        .size = [input lengthOfBytesUsingEncoding:NSUTF8StringEncoding]
    });

    [input release]; // retain in loop_schedule(&main_loop, ...) (in _queue) somewhere
  }
}

static CFDataRef local_server_callback(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {
  NeoVimXpcImpl *wrapper = (NeoVimXpcImpl *) info;
  NSData *responseData = [wrapper handleMessageWithId:msgid data:(NSData *) data];
  if (responseData == NULL) {
    return NULL;
  }

  return CFDataCreate(kCFAllocatorDefault, responseData.bytes, responseData.length);
}

@implementation NeoVimXpcImpl {
  NSString *_uuid;

  CFMessagePortRef _localServerPort;
  CFRunLoopSourceRef _localServerRunLoopSrc;
  NSThread *_localServerThread;

  CFMessagePortRef _remoteServerPort;
  NSRunLoop *_localServerRunLoop;
}

- (instancetype)initWithNeoVimUi:(id <NeoVimUiBridgeProtocol>)ui {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  _queue = dispatch_queue_create("xpc_callback_queue", DISPATCH_QUEUE_SERIAL);

  // set $VIMRUNTIME to ${RESOURCE_PATH_OF_XPC_BUNDLE}/runtime
  NSString *runtimePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"runtime"];
  setenv("VIMRUNTIME", runtimePath.fileSystemRepresentation, true);

  uv_mutex_init(&_mutex);
  uv_cond_init(&_condition);

  uv_thread_create(&_nvim_thread, run_neovim, NULL);

  // continue only after our UI main code for neovim has been fully initialized
  uv_mutex_lock(&_mutex);
  while (!_is_ui_launched) {
    uv_cond_wait(&_condition, &_mutex);
  }
  uv_mutex_unlock(&_mutex);

  uv_cond_destroy(&_condition);
  uv_mutex_destroy(&_mutex);

  [ui retain];
  _neo_vim_osx_ui = ui;
  [_neo_vim_osx_ui neoVimUiIsReady];

  _backspace = [[NSString alloc] initWithString:@"<BS>"];

  return self;
}

- (void)dealloc {
  [_neo_vim_osx_ui release];
  [_backspace release];

  [_uuid release];

  CFMessagePortInvalidate(_remoteServerPort);
  CFRelease(_remoteServerPort);

  CFMessagePortInvalidate(_localServerPort);
  CFRelease(_localServerPort);
  CFRelease(_localServerRunLoopSrc);

  [_localServerThread cancel];
  [_localServerRunLoop release];
  [_localServerThread release];

  // FIXME: uv_thread_join(&thread) here after terminating neovim

  [super dealloc];
}

- (void)probe {
  // noop
}

- (void)deleteCharacters:(NSInteger)count {
  xpc_sync(^{
    _marked_delta = 0;

    // Very ugly: When we want to have the Hanja for 하, Cocoa first finalizes 하, then sets the Hanja as marked text.
    // The main app will call this method when this happens, thus compute how many cell we have to go backward to
    // correctly mark the will-be-soon-inserted Hanja... See also docs/notes-on-cocoa-text-input.md
    int emptyCounter = 0;
    for (int i = 0; i < count; i++) {
      _marked_delta -= 1;

      // TODO: -1 because we assume that the cursor is one cell ahead, probably not always correct...
      schar_T character = ScreenLines[_put_row * screen_Rows + _put_column - i - emptyCounter - 1];
      if (character == 0x00 || character == ' ') {
        // FIXME: dunno yet, why we have to also match ' '...
        _marked_delta -= 1;
        emptyCounter += 1;
      }
    }

//    log4Debug("put cursor: %d:%d, count: %li, delta: %d", _put_row, _put_column, count, _marked_delta);

    for (int i = 0; i < count; i++) {
      loop_schedule(&main_loop, event_create(1, neovim_input, 1, [_backspace retain])); // release in neovim_input
    }
  });
}

- (void)forceRedraw {
  loop_schedule(&main_loop, event_create(1, force_redraw, 0));
}

- (void)resizeToWidth:(int)width height:(int)height {
  xpc_sync(^{

    set_ui_size(_xpc_ui_data->bridge, width, height);
    loop_schedule(&main_loop, event_create(1, refresh_ui, 0));
  });
}

- (void)vimInput:(NSString *_Nonnull)input {
  xpc_sync(^{
    if (_marked_text == nil) {
      loop_schedule(&main_loop, event_create(1, neovim_input, 1, [input retain])); // release in neovim_input
      return;
    }

    // Handle cases like ㅎ -> arrow key: The previously marked text is the same as the finalized text which should
    // inserted. Neovim's drawing code is optimized such that it does not call put in this case again, thus, we have
    // to manually unmark the cells in the main app.
    if ([_marked_text isEqualToString:input]) {
//      log4Debug("unmarking text: '%@'\t now at %d:%d", input, _put_row, _put_column);
      const char *str = [_marked_text cStringUsingEncoding:NSUTF8StringEncoding];
      size_t cellCount = mb_string2cells((const char_u *) str);
      for (int i = 1; i <= cellCount; i++) {
//        log4Debug("unmarking at %d:%d", _put_row, _put_column - i);
        [_neo_vim_osx_ui unmarkRow:_put_row column:MAX(_put_column - i, 0)];
      }
    }

    [self deleteMarkedText];
    loop_schedule(&main_loop, event_create(1, neovim_input, 1, [input retain])); // release in neovim_input
  });
}

- (void)vimInputMarkedText:(NSString *_Nonnull)markedText {
  xpc_sync(^{
    if (_marked_text == nil) {
      _marked_row = _put_row;
      _marked_column = _put_column + _marked_delta;
//      log4Debug("marking position: %d:%d(%d + %d)", _put_row, _marked_column, _put_column, _marked_delta);
      _marked_delta = 0;
    } else {
      [self deleteMarkedText];
    }

//    log4Debug("inserting marked text '%@' at %d:%d", markedText, _put_row, _put_column);
    [self insertMarkedText:markedText];
  });
}

- (void)insertMarkedText:(NSString *_Nonnull)markedText {
  _marked_text = [markedText retain]; // release when the final text is input in -vimInput

  loop_schedule(&main_loop, event_create(1, neovim_input, 1, [_marked_text retain])); // release in neovim_input
}

- (void)deleteMarkedText {
  NSUInteger length = [_marked_text lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;

  [_marked_text release];
  _marked_text = nil;

  for (int i = 0; i < length; i++) {
    loop_schedule(&main_loop, event_create(1, neovim_input, 1, [_backspace retain])); // release in neovim_input
  }
}

- (void)debug1 {
  char_u *ptr = get_cursor_pos_ptr();
  printf("-----------------\n'");
  for (int i = 0; i < 10; i++) {
    printf("%c", (unsigned char) *(ptr++));
  }
  printf("'\n---------------------\n");
}

- (void)startServerWithUuid:(NSString * _Nonnull)uuid {
  _uuid = [uuid retain];

  _localServerThread = [[NSThread alloc] initWithTarget:self selector:@selector(runLocalServer) object:nil];
  [_localServerThread start];

  [self sendAckToMain];
}

- (NSData *)handleMessageWithId:(SInt32)msgid data:(NSData *)data {
  if (msgid == 13) {
    NSLog(@"Hey you!!!!!!!!!!!!!!");
  }

  return nil;
}

- (void)runLocalServer {
  unsigned char shouldFree = false;
  CFMessagePortContext localContext = {
      .version = 0,
      .info = (void *) self,
      .retain = NULL,
      .release = NULL,
      .copyDescription = NULL
  };
  _localServerPort = CFMessagePortCreateLocal(
      kCFAllocatorDefault,
      (CFStringRef) _uuid,
      local_server_callback,
      &localContext,
      &shouldFree
  );
  _localServerRunLoopSrc = CFMessagePortCreateRunLoopSource(kCFAllocatorDefault, _localServerPort, 0);
  _localServerRunLoop = [[NSRunLoop currentRunLoop] retain];
  CFRunLoopRef cfRunLoop = _localServerRunLoop.getCFRunLoop;
  CFRunLoopAddSource(cfRunLoop, _localServerRunLoopSrc, kCFRunLoopCommonModes);
  [_localServerRunLoop run];
}

- (void)sendAckToMain {
  NSString *remoteServerName = [NSString stringWithFormat:@"com.qvacua.nvox.%@", _uuid];
  NSLog(@"remote server name for neovim: %@", remoteServerName);
  _remoteServerPort = CFMessagePortCreateRemote(kCFAllocatorDefault, (CFStringRef) remoteServerName);
  NSData *data = [@"JO" dataUsingEncoding:NSUTF8StringEncoding];
  SInt32 responseCode = CFMessagePortSendRequest(_remoteServerPort, 0, (CFDataRef) data, 10, 10, NULL, NULL);
  if (responseCode == kCFMessagePortSuccess) {
    NSLog(@"SUCESSSfully sent!");
  } else {
    NSLog(@"@@@@@@@@@@@@");
  }
}

@end
