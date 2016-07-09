/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "server_ui.h"
#import "NeoVimUiBridgeProtocol.h"
#import "Logging.h"
#import "server_globals.h"
#import "NeoVimServer.h"

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
} ServerUiData;

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

static ServerUiData *_xpc_ui_data;

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

static inline void queue(void (^block)()) {
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
  ((ServerUiData *) data)->cont_received = true;
}

static void osx_xpc_ui_scheduler(Event event, void *d) {
  UI *ui = d;
  ServerUiData *data = ui->data;
  loop_schedule(data->loop, event);
}

static void osx_xpc_ui_main(UIBridgeData *bridge, UI *ui) {
  Loop loop;
  loop_init(&loop, NULL);

  _xpc_ui_data = xcalloc(1, sizeof(ServerUiData));
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
  ServerUiData *data = ui->data;
  data->cont_received = false;

  kill(0, SIGTSTP);

  while (!data->cont_received) {
    // poll the event loop until SIGCONT is received
    loop_poll_events(data->loop, -1);
  }

  CONTINUE(data->bridge);
}

static void xpc_ui_resize(UI *ui __unused, int width, int height) {
  queue(^{
    int values[] = { width, height };
    NSData *data = [[NSData alloc] initWithBytes:values length:(2 * sizeof(int))];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdResize data:data];
    [data release];
    NSLog(@"resized");
  });
}

static void xpc_ui_clear(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdClear];
  });
}

static void xpc_ui_eol_clear(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdEolClear];
  });
}

static void xpc_ui_cursor_goto(UI *ui __unused, int row, int col) {
  queue(^{
    _put_row = row;
    _put_column = col;

    int values[] = { row, col, screen_cursor_row(), screen_cursor_column() };
    NSData *data = [[NSData alloc] initWithBytes:values length:(4 * sizeof(int))];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdSetPosition data:data];
    [data release];
  });
}

static void xpc_ui_update_menu(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdSetMenu];
  });
}

static void xpc_ui_busy_start(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdBusyStart];
  });
}

static void xpc_ui_busy_stop(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdBusyStop];
  });
}

static void xpc_ui_mouse_on(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdMouseOn];
  });
}

static void xpc_ui_mouse_off(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdMouseOff];
  });
}

static void xpc_ui_mode_change(UI *ui __unused, int mode) {
  queue(^{
    int value = mode;
    NSData *data = [[NSData alloc] initWithBytes:&value length:(1 * sizeof(int))];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdModeChange data:data];
    [data release];
  });
}

static void xpc_ui_set_scroll_region(UI *ui __unused, int top, int bot, int left, int right) {
  queue(^{
    int values[] = { top, bot, left, right };
    NSData *data = [[NSData alloc] initWithBytes:values length:(4 * sizeof(int))];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdSetScrollRegion data:data];
    [data release];
  });
}

static void xpc_ui_scroll(UI *ui __unused, int count) {
  queue(^{
    int value = count;
    NSData *data = [[NSData alloc] initWithBytes:&value length:(1 * sizeof(int))];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdScroll data:data];
    [data release];
  });
}

static void xpc_ui_highlight_set(UI *ui __unused, HlAttrs attrs) {
  queue(^{
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

    NSData *data = [[NSData alloc] initWithBytes:&cellAttrs length:sizeof(CellAttributes)];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdSetHighlightAttributes data:data];
    [data release];
  });
}

static void xpc_ui_put(UI *ui __unused, uint8_t *str, size_t len) {
  queue(^{
    NSString *string = [[NSString alloc] initWithBytes:str length:len encoding:NSUTF8StringEncoding];
//    printf("%s", [string cStringUsingEncoding:NSUTF8StringEncoding]);

    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (_marked_text != nil && _marked_row == _put_row && _marked_column == _put_column) {
//      log4Debug("putting marked text: '%@'", string);
      [_neovim_server sendMessageWithId:NeoVimServerMsgIdPutMarked data:data];
    } else if (_marked_text != nil && len == 0 && _marked_row == _put_row && _marked_column == _put_column - 1) {
//      log4Debug("putting marked text cuz zero");
      [_neovim_server sendMessageWithId:NeoVimServerMsgIdPutMarked data:data];
    } else {
//      log4Debug("putting non-marked text: '%@'", string);
      [_neovim_server sendMessageWithId:NeoVimServerMsgIdPut data:data];
    }

    _put_column += 1;
    [string release];
  });
}

static void xpc_ui_bell(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdBell];
  });
}

static void xpc_ui_visual_bell(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdVisualBell];
  });
}

static void xpc_ui_flush(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdFlush];
  });
}

static void xpc_ui_update_fg(UI *ui __unused, int fg) {
  queue(^{
    int value;

    if (fg == -1) {
      value = _default_foreground;
      NSData *data = [[NSData alloc] initWithBytes:&value length:(1 * sizeof(int))];
      [_neovim_server sendMessageWithId:NeoVimServerMsgIdScroll data:data];
      [data release];

      return;
    }

    _default_foreground = pun_type(unsigned int, fg);

    value = fg;
    NSData *data = [[NSData alloc] initWithBytes:&value length:(1 * sizeof(int))];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdScroll data:data];
    [data release];
  });
}

static void xpc_ui_update_bg(UI *ui __unused, int bg) {
  queue(^{
    int value;

    if (bg == -1) {
      value = _default_background;
      NSData *data = [[NSData alloc] initWithBytes:&value length:(1 * sizeof(int))];
      [_neovim_server sendMessageWithId:NeoVimServerMsgIdScroll data:data];
      [data release];

      return;
    }

    _default_background = pun_type(unsigned int, bg);
    value = bg;
    NSData *data = [[NSData alloc] initWithBytes:&value length:(1 * sizeof(int))];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdScroll data:data];
    [data release];
  });
}

static void xpc_ui_update_sp(UI *ui __unused, int sp) {
  queue(^{
    int value;

    if (sp == -1) {
      value = _default_special;
      NSData *data = [[NSData alloc] initWithBytes:&value length:(1 * sizeof(int))];
      [_neovim_server sendMessageWithId:NeoVimServerMsgIdScroll data:data];
      [data release];

      return;
    }

    _default_special = pun_type(unsigned int, sp);
    value = sp;
    NSData *data = [[NSData alloc] initWithBytes:&value length:(1 * sizeof(int))];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdScroll data:data];
    [data release];
  });
}

static void xpc_ui_suspend(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdSuspend];

    ServerUiData *data = ui->data;
    // FIXME: dunno whether we need this: copied from tui.c
    // kill(0, SIGTSTP) won't stop the UI thread, so we must poll for SIGCONT
    // before continuing. This is done in another callback to avoid
    // loop_poll_events recursion
    queue_put_event(data->loop->fast_events, event_create(1, suspend_event, 1, ui));
  });
}

static void xpc_ui_set_title(UI *ui __unused, char *title) {
  queue(^{
    NSString *string = [[NSString alloc] initWithCString:title encoding:NSUTF8StringEncoding];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdSetTitle data:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [string release];
  });
}

static void xpc_ui_set_icon(UI *ui __unused, char *icon) {
  queue(^{
    NSString *string = [[NSString alloc] initWithCString:icon encoding:NSUTF8StringEncoding];
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdSetIcon data:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [string release];
  });
}

static void xpc_ui_stop(UI *ui __unused) {
  queue(^{
    [_neovim_server sendMessageWithId:NeoVimServerMsgIdStop];

    ServerUiData *data = (ServerUiData *) ui->data;
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

void start_neovim() {
  _queue = dispatch_queue_create("com.qvacua.nvox.neovim-server.queue", DISPATCH_QUEUE_SERIAL);

  // set $VIMRUNTIME to ${RESOURCE_PATH_OF_XPC_BUNDLE}/runtime
  NSString *bundlePath = [NSBundle bundleForClass:[NeoVimServer class]].bundlePath;
  NSString *resourcesPath = [bundlePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"Resources"];
  NSString *runtimePath = [resourcesPath stringByAppendingPathComponent:@"runtime"];
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

  _backspace = [[NSString alloc] initWithString:@"<BS>"];

  [_neovim_server sendMessageWithId:NeoVimServerMsgIdNeoVimReady];
}

