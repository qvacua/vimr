/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import "NeoVimXpcImpl.h"
#import "NeoVimUiBridgeProtocol.h"

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

static unsigned int default_foreground = qDefaultForeground;
static unsigned int default_background = qDefaultBackground;
static unsigned int default_special = qDefaultSpecial;

// The thread in which neovim's main runs
static uv_thread_t _nvim_thread;

// Condition variable used by the XPC's init to wait till our custom UI initialization is finished inside neovim
static bool _is_ui_launched = false;
static uv_mutex_t _mutex;
static uv_cond_t _condition;

static id <NeoVimUiBridgeProtocol> _neo_vim_osx_ui;

static int _row = 0;
static int _column = 0;
static int _markedRow = 0;
static int _markedColumn = 0;
static NSString *_markedText = nil;

static dispatch_queue_t _queue;

static void xpc_async(void (^block)()) {
  dispatch_async(_queue, block);
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

  XpcUiData *data = xcalloc(1, sizeof(XpcUiData));
  ui->data = data;
  data->bridge = bridge;
  data->loop = &loop;

  // FIXME: dunno whether we need this: copied from tui.c
  signal_watcher_init(data->loop, &data->cont_handle, data);
  signal_watcher_start(&data->cont_handle, sigcont_cb, SIGCONT);

  bridge->bridge.width = 30;
  bridge->bridge.height = 10;

  data->stop = false;
  CONTINUE(bridge);

  uv_mutex_lock(&_mutex);
  _is_ui_launched = true;
  uv_cond_signal(&_condition);
  uv_mutex_unlock(&_mutex);

  while (!data->stop) {
    loop_poll_events(&loop, -1);
  }

  ui_bridge_stopped(bridge);
  loop_close(&loop);

  xfree(data);
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
  xpc_async(^{
      //printf("resize: %d:%d\n", width, height);
      [_neo_vim_osx_ui resizeToWidth:width height:height];
  });
}

static void xpc_ui_clear(UI *ui __unused) {
  xpc_async(^{
      //printf("clear\n");
      [_neo_vim_osx_ui clear];
  });
}

static void xpc_ui_eol_clear(UI *ui __unused) {
  xpc_async(^{
      //printf("eol clear\n");
      [_neo_vim_osx_ui eolClear];
  });
}

static void xpc_ui_cursor_goto(UI *ui __unused, int row, int col) {
  xpc_async(^{
      //printf("cursor goto %d:%d\n", row, col);
      _row = row;
      _column = col;

      [_neo_vim_osx_ui cursorGotoRow:row column:col];
  });
}

static void xpc_ui_update_menu(UI *ui __unused) {
  xpc_async(^{
      //printf("update menu\n");
      [_neo_vim_osx_ui updateMenu];
  });
}

static void xpc_ui_busy_start(UI *ui __unused) {
  xpc_async(^{
      //printf("busy start\n");
      [_neo_vim_osx_ui busyStart];
  });
}

static void xpc_ui_busy_stop(UI *ui __unused) {
  xpc_async(^{
      //printf("busy stop\n");
      [_neo_vim_osx_ui busyStop];
  });
}

static void xpc_ui_mouse_on(UI *ui __unused) {
  xpc_async(^{
      //printf("mouse on\n");
      [_neo_vim_osx_ui mouseOn];
  });
}

static void xpc_ui_mouse_off(UI *ui __unused) {
  xpc_async(^{
      //printf("mouse off\n");
      [_neo_vim_osx_ui mouseOff];
  });
}

static void xpc_ui_mode_change(UI *ui __unused, int mode) {
  xpc_async(^{
      //printf("mode change %04x\n", mode);
      [_neo_vim_osx_ui modeChange:mode];
  });
}

static void xpc_ui_set_scroll_region(UI *ui __unused, int top, int bot, int left, int right) {
  xpc_async(^{
      //printf("set scroll region: %d, %d, %d, %d\n", top, bot, left, right);
      [_neo_vim_osx_ui setScrollRegionToTop:top bottom:bot left:left right:right];
  });
}

static void xpc_ui_scroll(UI *ui __unused, int count) {
  xpc_async(^{
      //printf("scroll %d\n", count);
      [_neo_vim_osx_ui scroll:count];
  });
}

static void xpc_ui_highlight_set(UI *ui __unused, HlAttrs attrs) {
  xpc_async(^{
      //printf("highlight set\n");
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

      unsigned int fg = attrs.foreground == -1 ? default_foreground : pun_type(unsigned int, attrs.foreground);
      unsigned int bg = attrs.background == -1 ? default_background : pun_type(unsigned int, attrs.background);

      cellAttrs.foreground = attrs.reverse ? bg : fg;
      cellAttrs.background = attrs.reverse ? fg : bg;
      cellAttrs.special = attrs.special == -1 ? default_special : pun_type(unsigned int, attrs.special);

      [_neo_vim_osx_ui highlightSet:cellAttrs];
  });
}

static void xpc_ui_put(UI *ui __unused, uint8_t *str, size_t len) {
  xpc_async(^{
      NSString *string = [[NSString alloc] initWithBytes:str length:len encoding:NSUTF8StringEncoding];
//      printf("put: %lu:'%s'\n", len, [string cStringUsingEncoding:NSUTF8StringEncoding]);

      if (_markedText != nil && _markedColumn == _column && _markedRow == _row) {
        [_neo_vim_osx_ui putMarkedText:string];
      } else if (_markedText != nil && len == 0 && _markedColumn == _column - 1) {
        [_neo_vim_osx_ui putMarkedText:string];
      } else {
        [_neo_vim_osx_ui put:string];
      }

      _column += 1;
      [string release];
  });
}

static void xpc_ui_bell(UI *ui __unused) {
  xpc_async(^{
      //printf("bell\n");
      [_neo_vim_osx_ui bell];
  });
}

static void xpc_ui_visual_bell(UI *ui __unused) {
  xpc_async(^{
      //printf("visual bell\n");
      [_neo_vim_osx_ui visualBell];
  });
}

static void xpc_ui_flush(UI *ui __unused) {
  xpc_async(^{
      //printf("flush\n");
      [_neo_vim_osx_ui flush];
  });
}

static void xpc_ui_update_fg(UI *ui __unused, int fg) {
  xpc_async(^{
//  printf("update fg: %x\n", fg);
      if (fg != -1) {
        default_foreground = pun_type(unsigned int, fg);
      }
      [_neo_vim_osx_ui updateForeground:fg];
  });
}

static void xpc_ui_update_bg(UI *ui __unused, int bg) {
  xpc_async(^{
//  printf("update bg: %x\n", bg);
      if (bg != -1) {
        default_background = pun_type(unsigned int, bg);
      }
      [_neo_vim_osx_ui updateBackground:bg];
  });
}

static void xpc_ui_update_sp(UI *ui __unused, int sp) {
  xpc_async(^{
//  printf("update sp: %x\n", sp);
      if (sp != -1) {
        default_special = pun_type(unsigned int, sp);
      }
      [_neo_vim_osx_ui updateSpecial:sp];
  });
}

static void xpc_ui_suspend(UI *ui __unused) {
  xpc_async(^{
      //printf("suspend\n");
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
  xpc_async(^{
      //printf("set title: %s\n", title);
      NSString *string = [[NSString alloc] initWithCString:title encoding:NSUTF8StringEncoding];
      [_neo_vim_osx_ui setTitle:string];
      [string release];
  });
}

static void xpc_ui_set_icon(UI *ui __unused, char *icon) {
  xpc_async(^{
      //printf("set title: %s\n", icon);
      NSString *string = [[NSString alloc] initWithCString:icon encoding:NSUTF8StringEncoding];
      [_neo_vim_osx_ui setIcon:string];
      [string release];
  });
}

static void xpc_ui_stop(UI *ui __unused) {
  xpc_async(^{
      //printf("stop\n");
      [_neo_vim_osx_ui stop];

      XpcUiData *data = (XpcUiData *) ui->data;
      data->stop = true;
  });
}

static void run_neovim(void *arg __unused) {
  char *argv[1];
  argv[0] = "nvim";

  int returnCode = nvim_main(1, argv);

  NSLog(@"neovim's main returned with code: %d", returnCode);
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

static void neovim_input(void **argv) {
  NSString *input = (NSString *) argv[0];

  // FIXME: check the length of the consumed bytes by neovim and if not fully consumed, call vim_input again.
  vim_input((String) {
      .data = (char *) input.UTF8String,
      .size = [input lengthOfBytesUsingEncoding:NSUTF8StringEncoding]
  });

  [input release]; // retain in loop_schedule(&main_loop, ...) (in _queue) somewhere
}

@implementation NeoVimXpcImpl

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

  // casting because [ui retain] returns an NSObject
  _neo_vim_osx_ui = (id <NeoVimUiBridgeProtocol>) [ui retain];

  return self;
}

- (void)dealloc {
  [_neo_vim_osx_ui release];
  // FIXME: uv_thread_join(&thread) here after terminating neovim

  [super dealloc];
}

- (void)probe {
  // noop
}

- (void)vimInput:(NSString *_Nonnull)input {
  xpc_async(^{
      if (_markedText == nil) {
        loop_schedule(&main_loop, event_create(1, neovim_input, 1, [input retain])); // release in neovim_input
        return;
      }

      // Handle cases like ㅎ -> arrow key: The previously marked text is the same as the finalized text which should
      // inserted. Neovim's drawing code is optimized such that it does not call put in this case again, thus, we
      // have to manually unmark the cells in the main app.
      if ([_markedText isEqualToString:input]) {
        [_neo_vim_osx_ui unmarkRow:_row column:MAX(_column - 1, 0)];
        if (ScreenLines[_row * screen_Columns + MAX(_column - 1, 0)] == 0x00) {
          [_neo_vim_osx_ui unmarkRow:_row column:MAX(_column - 2, 0)];
        }
      }

      [self deleteMarkedText];
      loop_schedule(&main_loop, event_create(1, neovim_input, 1, [input retain])); // release in neovim_input
  });
}

- (void)vimInputMarkedText:(NSString *_Nonnull)markedText {
  xpc_async(^{
      if (_markedText != nil) {
        [self deleteMarkedText];
      }

      [self insertMarkedText:markedText];
  });
}

- (void)insertMarkedText:(NSString *_Nonnull)markedText {
  _markedRow = _row;
  _markedColumn = _column;
  _markedText = [markedText retain]; // release when the final text is input in -vimInput

  loop_schedule(&main_loop, event_create(1, neovim_input, 1, [_markedText retain])); // release in neovim_input
}

- (void)deleteMarkedText {
  NSUInteger length = [_markedText lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;

  [_markedText release];
  _markedText = nil;

  NSString *backspace = [[NSString alloc] initWithString:@"<BS>"];
  for (int i = 0; i < length; i++) {
    loop_schedule(&main_loop, event_create(1, neovim_input, 1, [backspace retain])); // release in neovim_input
  }
  [backspace release];
}

- (void)debugScreenLines {
  NSLog(@"--- ScreenLines ---");
  for (int i = 0; i < 20; i++) {
    printf("%c,\n", ScreenLines[i]);
  }
}

@end
