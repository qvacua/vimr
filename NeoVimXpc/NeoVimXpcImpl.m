/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <objc/message.h>

#import "NeoVimXpcImpl.h"
#import "NeoVimUi.h"


/**
 * FileInfo and Boolean are #defined by Carbon and NeoVim: Since we don't need the Carbon versions of them, we rename
 * them.
 */
#define FileInfo CarbonFileInfo
#define Boolean CarbonBoolean

#import <nvim/vim.h>
#import <nvim/api/vim.h>
#import <nvim/ui.h>
#import <nvim/ui_bridge.h>
#import <nvim/event/stream.h>
#import <nvim/event/signal.h>

void (*objc_msgSend_no_arg)(id, SEL) = (void *) objc_msgSend;
void (*objc_msgSend_string)(id, SEL, NSString *) = (void *) objc_msgSend;
void (*objc_msgSend_int)(id, SEL, int) = (void *) objc_msgSend;
void (*objc_msgSend_2_int)(id, SEL, int, int) = (void *) objc_msgSend;
void (*objc_msgSend_4_int)(id, SEL, int, int, int, int) = (void *) objc_msgSend;
void (*objc_msgSend_hlattrs)(id, SEL, HighlightAttributes) = (void *) objc_msgSend;

// we declare nvim_main because it's not declared in any header files of neovim
extern int nvim_main(int argc, char **argv);

static bool is_ui_launched = false;
static NSCondition *uiLaunchCondition;

static id <NeoVimUi> neoVimOsxUi;

static inline NSString *string_from_bytes(uint8_t *str, size_t len) {
  return [[NSString alloc] initWithBytes:str length:len encoding:NSUTF8StringEncoding];
}

static inline NSString *string_from_cstr(char *cstr) {
  return [[NSString alloc] initWithCString:cstr encoding:NSUTF8StringEncoding];
}

static inline String nvim_string_from_string(NSString *str) {
  return (String) {.data=(char *) str.UTF8String, .size=[str lengthOfBytesUsingEncoding:NSUTF8StringEncoding]};
}

typedef struct {
    UIBridgeData *bridge;
    Loop *loop;
    Stream read_stream;

    bool stop;
    bool cont_received;

    // FIXME: dunno whether we need this: copied from tui.c
    SignalWatcher cont_handle;
} OsxXpcUiData;

static void sigcont_cb(SignalWatcher *watcher, int signum, void *data) {
  ((OsxXpcUiData *) data)->cont_received = true;
}

static void osx_xpc_ui_scheduler(Event event, void *d) {
  UI *ui = d;
  OsxXpcUiData *data = ui->data;
  loop_schedule(data->loop, event);
}

static void osx_xpc_ui_main(UIBridgeData *bridge, UI *ui) {
  Loop loop;
  loop_init(&loop, NULL);

  OsxXpcUiData *data = xcalloc(1, sizeof(OsxXpcUiData));
  ui->data = data;
  data->bridge = bridge;
  data->loop = &loop;

  signal_watcher_init(data->loop, &data->cont_handle, data);
  signal_watcher_start(&data->cont_handle, sigcont_cb, SIGCONT);

  bridge->bridge.width = 10;
  bridge->bridge.height = 5;

  data->stop = false;
  CONTINUE(bridge);

  [uiLaunchCondition lock];
  is_ui_launched = true;
  [uiLaunchCondition signal];
  [uiLaunchCondition unlock];

  while (!data->stop) {
    loop_poll_events(&loop, -1);
  }

  ui_bridge_stopped(bridge);
  loop_close(&loop);

  xfree(data);
  xfree(ui);
}

// copied from tui.c
static void suspend_event(void **argv) {
  UI *ui = argv[0];
  OsxXpcUiData *data = ui->data;
  data->cont_received = false;

  kill(0, SIGTSTP);

  while (!data->cont_received) {
    // poll the event loop until SIGCONT is received
    loop_poll_events(data->loop, -1);
  }

  CONTINUE(data->bridge);
}

static void xpc_ui_resize(UI *ui, int rows, int columns) {
  objc_msgSend_2_int(neoVimOsxUi, @selector(resize:columns:), rows, columns);
}

static void xpc_ui_clear(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(clear));
}

static void xpc_ui_eol_clear(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(eolClear));
}

static void xpc_ui_cursor_goto(UI *ui, int row, int col) {
  objc_msgSend_2_int(neoVimOsxUi, @selector(cursorGoto:column:), row, col);
}

static void xpc_ui_update_menu(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(updateMenu));
}

static void xpc_ui_busy_start(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(busyStart));
}

static void xpc_ui_busy_stop(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(busyStop));
}

static void xpc_ui_mouse_on(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(mouseOn));
}

static void xpc_ui_mouse_off(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(mouseOff));
}

static void xpc_ui_mode_change(UI *ui, int mode) {
  objc_msgSend_int(neoVimOsxUi, @selector(modeChange:), mode);
}

static void xpc_ui_set_scroll_region(UI *ui, int top, int bot, int left, int right) {
  objc_msgSend_4_int(neoVimOsxUi, @selector(setScrollRegion:bottom:left:right:), top, bot, left, right);
}

static void xpc_ui_scroll(UI *ui, int count) {
  objc_msgSend_int(neoVimOsxUi, @selector(scroll:), count);
}

static void xpc_ui_highlight_set(UI *ui, HlAttrs attrs) {
  objc_msgSend_hlattrs(neoVimOsxUi, @selector(highlightSet:), (*(HighlightAttributes *)(&attrs)));
}

static void xpc_ui_put(UI *ui, uint8_t *str, size_t len) {
  objc_msgSend_string(neoVimOsxUi, @selector(put:), string_from_bytes(str, len));
}

static void xpc_ui_bell(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(bell));
}

static void xpc_ui_visual_bell(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(visualBell));
}

static void xpc_ui_flush(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(flush));
}

static void xpc_ui_update_fg(UI *ui, int fg) {
  objc_msgSend_int(neoVimOsxUi, @selector(updateFg:), fg);
}

static void xpc_ui_update_bg(UI *ui, int bg) {
  objc_msgSend_int(neoVimOsxUi, @selector(updateBg:), bg);
}

static void xpc_ui_update_sp(UI *ui, int sp) {
  objc_msgSend_int(neoVimOsxUi, @selector(updateSp:), sp);
}

static void xpc_ui_suspend(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(suspend));

  OsxXpcUiData *data = ui->data;
  // copied from tui.c
  // kill(0, SIGTSTP) won't stop the UI thread, so we must poll for SIGCONT
  // before continuing. This is done in another callback to avoid
  // loop_poll_events recursion
  queue_put_event(data->loop->fast_events, event_create(1, suspend_event, 1, ui));
}

static void xpc_ui_set_title(UI *ui, char *title) {
  objc_msgSend_string(neoVimOsxUi, @selector(setTitle:), string_from_cstr(title));
}

static void xpc_ui_set_icon(UI *ui, char *icon) {
  objc_msgSend_string(neoVimOsxUi, @selector(setTitle:), string_from_cstr(icon));
}

static void xpc_ui_stop(UI *ui) {
  objc_msgSend_no_arg(neoVimOsxUi, @selector(stop));

  OsxXpcUiData *data = (OsxXpcUiData *) ui->data;
  data->stop = true;
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

  NSLog(@"attaching ui");
  ui_bridge_attach(ui, osx_xpc_ui_main, osx_xpc_ui_scheduler);
}

@implementation NeoVimXpcImpl {
  NSThread *_neoVimThread;
}

- (instancetype)initWithNeoVimUi:(id<NeoVimUi>)ui {
  self = [super init];
  if (self == nil) {
    return nil;
  }

  uiLaunchCondition = [NSCondition new];

  // set $VIMRUNTIME to ${RESOURCE_PATH_OF_XPC_BUNDLE}/runtime
  NSString *runtimePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"runtime"];
  setenv("VIMRUNTIME", runtimePath.fileSystemRepresentation, true);

  _neoVimThread = [[NSThread alloc] initWithTarget:self selector:@selector(runNeoVim:) object:self];
  [_neoVimThread start];

  // return only when the ui is launched
  [uiLaunchCondition lock];
  while (!is_ui_launched) {
    [uiLaunchCondition wait];
  }
  [uiLaunchCondition unlock];

  neoVimOsxUi = ui;

  return self;
}

- (void)runNeoVim:(id)sender {
  char *argv[1];
  argv[0] = "nvim";

  nvim_main(1, argv);
}

- (void)doSth {
  NSString *str = @"i";
  NSLog(@"entering input");
  vim_input(nvim_string_from_string(str));

  str = @"test input";
  NSLog(@"entering some text");
  vim_input(nvim_string_from_string(str));

  unichar esc = 27; // = 001B
  str = [NSString stringWithCharacters:&esc length:1];
  NSLog(@"entering normal");
  vim_input(nvim_string_from_string(str));
}

@end
