/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>

#import "Logging.h"
#import "server_ui.h"
#import "NvimServer.h"
#import "CocoaCategories.h"

// FileInfo and Boolean are #defined by Carbon and NeoVim:
// Since we don't need the Carbon versions of them, we rename
// them.
#define FileInfo CarbonFileInfo
#define Boolean CarbonBoolean

#import <nvim/vim.h>
#import <nvim/api/vim.h>
#import <nvim/ui.h>
#import <nvim/ui_bridge.h>
#import <nvim/fileio.h>
#import <nvim/undo.h>
#import <nvim/mouse.h>
#import <nvim/screen.h>
#import <nvim/edit.h>
#import <nvim/syntax.h>
#import <nvim/aucmd.h>
#import <nvim/msgpack_rpc/helpers.h>
#import <msgpack.h>
#import <nvim/api/private/helpers.h>


#define let __auto_type const
#define var __auto_type
#define pun_type(t, x) (*((t *) (&(x))))


static NSInteger _default_foreground = 0xFF000000;
static NSInteger _default_background = 0xFFFFFFFF;
static NSInteger _default_special = 0xFFFF0000;

typedef struct {
  UIBridgeData *bridge;
  Loop *loop;

  bool stop;
} ServerUiData;

// We declare nvim_main because it's not declared in any header files of neovim
extern int nvim_main(int argc, char **argv);


// The thread in which neovim's main runs
static uv_thread_t _nvim_thread;

// Condition variable used by the XPC's init to wait till our custom UI initialization
// is finished inside neovim
static bool _is_ui_launched = false;
static uv_mutex_t _mutex;
static uv_cond_t _condition;

static ServerUiData *_server_ui_data;

static NSString *_marked_text = nil;

static NSInteger _marked_row = 0;
static NSInteger _marked_column = 0;

// for 하 -> hanja popup, Cocoa first inserts 하, then sets marked text,
// cf docs/notes-on-cocoa-text-input.md
static NSInteger _marked_delta = 0;

static NSInteger _put_row = -1;
static NSInteger _put_column = -1;

static NSString *_backspace = nil;

static bool _dirty = false;

static NSInteger _initialWidth = 30;
static NSInteger _initialHeight = 15;

static msgpack_sbuffer msg_sbuffer;
static msgpack_sbuffer flush_sbuffer;
static msgpack_packer *flush_packer;

#pragma mark Helper functions

static inline String vim_string_from(NSString *str) {
  return (String) {.data = (char *) str.cstr, .size = str.clength};
}

static void refresh_ui_screen(int type) {
  update_screen(type);
  setcursor();
  ui_flush();
}

static bool has_dirty_docs() {
  FOR_ALL_BUFFERS(buffer) {
    if (bufIsChanged(buffer)) {
      return true;
    }
  }

  return false;
}

typedef void (^pack_block)(msgpack_packer *packer);

static void send_msg_packing(NvimServerMsgId msgid, pack_block body) {
  msgpack_packer packer;
  msgpack_packer_init(&packer, &msg_sbuffer, msgpack_sbuffer_write);

  body(&packer);

  let data = CFDataCreateWithBytesNoCopy(
      kCFAllocatorDefault, (const UInt8 *) msg_sbuffer.data, msg_sbuffer.size, kCFAllocatorNull
  );
  [_neovim_server sendMessageWithId:msgid data:data];
  CFRelease(data);

  msgpack_sbuffer_clear(&msg_sbuffer);
}

static void pack_flush_data(RenderDataType type, pack_block body) {
  msgpack_pack_array(flush_packer, 2);
  msgpack_pack_int64(flush_packer, type);
  body(flush_packer);
}

static void send_dirty_status() {
  var new_dirty_status = has_dirty_docs();
  DLOG("dirty status: %d vs. %d", _dirty, new_dirty_status);
  if (_dirty == new_dirty_status) {
    return;
  }

  _dirty = new_dirty_status;
  DLOG("sending dirty status: %d", _dirty);

  send_msg_packing(NvimServerMsgIdDirtyStatusChanged, ^(msgpack_packer *packer) {
    if (_dirty) {
      msgpack_pack_true(packer);
    } else {
      msgpack_pack_false(packer);
    }
  });
}

static void send_cwd() {
  var temp = xmalloc(MAXPATHL);
  if (os_dirname(temp, MAXPATHL) == FAIL) {
    xfree(temp);
    [_neovim_server sendMessageWithId:NvimServerMsgIdCwdChanged];
  }

  send_msg_packing(NvimServerMsgIdCwdChanged, ^(msgpack_packer *packer) {
    let value = cstr_to_string((const char *) temp);
    msgpack_rpc_from_string(value, packer);
    api_free_string(value);
    xfree(temp);
  });
}

static HlAttrs HlAttrsFromAttrCode(int attr_code) {
  HlAttrs rgb_attrs = {false, false, false, false, false, -1, -1, -1};
  let aep = syn_cterm_attr2entry(attr_code);

  rgb_attrs.foreground = aep->rgb_fg_color;
  rgb_attrs.background = aep->rgb_bg_color;
  rgb_attrs.special = aep->rgb_sp_color;
  rgb_attrs.reverse = (bool) (aep->rgb_ae_attr & HL_INVERSE);

  return rgb_attrs;
}

static int foreground_for(HlAttrs attrs) {
  return attrs.reverse ? attrs.background : attrs.foreground;
}

static int background_for(HlAttrs attrs) {
  return attrs.reverse ? attrs.foreground : attrs.background;
}

static void send_colorscheme() {
  // It seems that the highlight groupt only gets updated when the screen is redrawn.
  // Since there's a guard var, probably it's safe to call it here...
  if (need_highlight_changed) {
    highlight_changed();
  }

  let visualAttrs = HlAttrsFromAttrCode(highlight_attr[HLF_V]);
  let dirAttrs = HlAttrsFromAttrCode(highlight_attr[HLF_D]);

  send_msg_packing(NvimServerMsgIdColorSchemeChanged, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 5);
    msgpack_pack_int64(packer, normal_fg);
    msgpack_pack_int64(packer, normal_bg);
    msgpack_pack_int64(packer, foreground_for(visualAttrs));
    msgpack_pack_int64(packer, background_for(visualAttrs));
    msgpack_pack_int64(packer, foreground_for(dirAttrs));
  });
}

static void insert_marked_text(NSString *markedText) {
  _marked_text = [markedText retain]; // release when the final text is input in -vimInput

  nvim_input(vim_string_from(markedText));
}

static void delete_marked_text() {
  let length = [_marked_text lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;

  [_marked_text release];
  _marked_text = nil;

  for (int i = 0; i < length; i++) {
    nvim_input(vim_string_from(_backspace));
  }
}

static void run_neovim(void *arg) {
  int argc;
  char **argv;

  @autoreleasepool {
    let nvimArgs = (NSArray<NSString *> *) arg;

    argc = (int) nvimArgs.count + 1;
    argv = (char **) malloc((argc + 1) * sizeof(char *));

    argv[0] = "nvim";
    for (var i = 0; i < nvimArgs.count; i++) {
      argv[i + 1] = (char *) nvimArgs[(NSUInteger) i].cstr;
    }

    [nvimArgs release]; // retained in start_neovim()
  }

  nvim_main(argc, argv);

  free(argv);
}

static void set_ui_size(UIBridgeData *bridge, int width, int height) {
  bridge->ui->width = width;
  bridge->ui->height = height;
  bridge->bridge.width = width;
  bridge->bridge.height = height;
}

static void server_ui_scheduler(Event event, void *d) {
  UI *ui = d;
  ServerUiData *data = ui->data;
  loop_schedule(data->loop, event);
}

static void server_ui_main(UIBridgeData *bridge, UI *ui) {
  msgpack_sbuffer_init(&msg_sbuffer);
  msgpack_sbuffer_init(&flush_sbuffer);
  flush_packer = msgpack_packer_new(&flush_sbuffer, msgpack_sbuffer_write);

  Loop loop;
  loop_init(&loop, NULL);

  _server_ui_data = xcalloc(1, sizeof(ServerUiData));
  ui->data = _server_ui_data;
  _server_ui_data->bridge = bridge;
  _server_ui_data->loop = &loop;

  set_ui_size(bridge, (int) _initialWidth, (int) _initialHeight);

  _server_ui_data->stop = false;
  CONTINUE(bridge);

  uv_mutex_lock(&_mutex);
  _is_ui_launched = true;
  uv_cond_signal(&_condition);
  uv_mutex_unlock(&_mutex);

  while (!_server_ui_data->stop) {
    loop_poll_events(&loop, -1);
  }

  ui_bridge_stopped(bridge);
  loop_close(&loop, false);

  xfree(_server_ui_data);
  xfree(ui);

  msgpack_sbuffer_clear(&flush_sbuffer);
  msgpack_packer_free(flush_packer);
}

#pragma mark NeoVim's UI callbacks

static void server_ui_flush(UI *ui __unused) {
  if (flush_sbuffer.size == 0) {
    return;
  }

  let data = CFDataCreateWithBytesNoCopy(
      kCFAllocatorDefault, (const UInt8 *) flush_sbuffer.data, flush_sbuffer.size, kCFAllocatorNull
  );
  [_neovim_server sendMessageWithId:NvimServerMsgIdFlush data:data];
  CFRelease(data);

  msgpack_sbuffer_clear(&flush_sbuffer);
  msgpack_packer_free(flush_packer);
  flush_packer = msgpack_packer_new(&flush_sbuffer, msgpack_sbuffer_write);
}

static void server_ui_resize(UI *ui __unused, Integer width, Integer height) {
  @autoreleasepool {
    server_ui_flush(NULL);

    send_msg_packing(NvimServerMsgIdResize, ^(msgpack_packer *packer) {
      msgpack_pack_array(packer, 2);
      msgpack_pack_int64(packer, width);
      msgpack_pack_int64(packer, height);
    });
  }
}

static void server_ui_clear(UI *ui __unused) {
  @autoreleasepool {
    server_ui_flush(NULL);
  }

  [_neovim_server sendMessageWithId:NvimServerMsgIdClear];
}

static void server_ui_eol_clear(UI *ui __unused) {
  pack_flush_data(RenderDataTypeEolClear, ^(msgpack_packer *packer) {
    msgpack_pack_nil(packer);
  });
}

static void server_ui_cursor_goto(UI *ui __unused, Integer row, Integer col) {
  _put_row = row;
  _put_column = col;

  DLOG("%d:%d - %d:%d - %d:%d", row, col, curwin->w_cursor.lnum, curwin->w_cursor.col + 1);

  pack_flush_data(RenderDataTypeGoto, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 4);
    msgpack_pack_int64(packer, row);
    msgpack_pack_int64(packer, col);
    msgpack_pack_int64(packer, curwin->w_cursor.lnum);
    msgpack_pack_int64(packer, curwin->w_cursor.col + 1);
  });
}

static void server_ui_update_menu(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdSetMenu];
}

static void server_ui_busy_start(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdBusyStart];
}

static void server_ui_busy_stop(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdBusyStop];
}

static void server_ui_mouse_on(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdMouseOn];
}

static void server_ui_mouse_off(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdMouseOff];
}

static void server_ui_mode_info_set(UI *ui __unused, Boolean enabled __unused, Array cursor_styles __unused) {
  // yet noop
}

static void server_ui_mode_change(UI *ui __unused, String mode_str __unused, Integer mode) {
  @autoreleasepool {
    send_msg_packing(NvimServerMsgIdModeChange, ^(msgpack_packer *packer) {
      msgpack_pack_int64(packer, mode);
    });
  }
}

static void server_ui_set_scroll_region(UI *ui __unused, Integer top, Integer bot, Integer left, Integer right) {
  @autoreleasepool {
    server_ui_flush(NULL);

    send_msg_packing(NvimServerMsgIdSetScrollRegion, ^(msgpack_packer *packer) {
      msgpack_pack_array(packer, 4);
      msgpack_pack_int64(packer, top);
      msgpack_pack_int64(packer, bot);
      msgpack_pack_int64(packer, left);
      msgpack_pack_int64(packer, right);
    });
  }
}

static void server_ui_scroll(UI *ui __unused, Integer count) {
  @autoreleasepool {
    server_ui_flush(NULL);

    send_msg_packing(NvimServerMsgIdScroll, ^(msgpack_packer *packer) {
      msgpack_pack_int64(packer, count);
    });
  }
}

static void server_ui_highlight_set(UI *ui __unused, HlAttrs attrs) {
  var trait = FontTraitNone;
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

  let fg = attrs.foreground == -1 ? _default_foreground : attrs.foreground;
  let bg = attrs.background == -1 ? _default_background : attrs.background;

  cellAttrs.foreground = attrs.reverse ? bg : fg;
  cellAttrs.background = attrs.reverse ? fg : bg;
  cellAttrs.special = attrs.special == -1 ? _default_special : pun_type(unsigned int, attrs.special);

  pack_flush_data(RenderDataTypeHighlight, ^(msgpack_packer *packer) {
    msgpack_pack_bin(packer, sizeof(cellAttrs));
    msgpack_pack_bin_body(packer, &cellAttrs, sizeof(cellAttrs));
  });
}

static void server_ui_put(UI *ui __unused, String str) {
  if (_marked_text != nil
      && _marked_row == _put_row
      && _marked_column == _put_column) {

    DLOG("putting marked text: '%s'", str.data);
    pack_flush_data(RenderDataTypePutMarked, ^(msgpack_packer *packer) {
      msgpack_rpc_from_string(str, packer);
    });

  } else if (_marked_text != nil
      && str.size == 0
      && _marked_row == _put_row
      && _marked_column == _put_column - 1) {

    DLOG("putting marked text cuz zero");
    pack_flush_data(RenderDataTypePutMarked, ^(msgpack_packer *packer) {
      msgpack_rpc_from_string(str, packer);
    });

  } else {

    DLOG("putting non-marked text: '%s'", str.data);
    pack_flush_data(RenderDataTypePut, ^(msgpack_packer *packer) {
      msgpack_rpc_from_string(str, packer);
    });

  }

  _put_column += 1;
}

static void server_ui_bell(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdBell];
}

static void server_ui_visual_bell(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdVisualBell];
}

static void server_ui_update_fg(UI *ui __unused, Integer fg) {
  @autoreleasepool {
    if (fg != -1) {
      _default_foreground = fg;
    }

    send_msg_packing(NvimServerMsgIdSetForeground, ^(msgpack_packer *packer) {
      msgpack_pack_int64(packer, _default_foreground);
    });
  }
}

static void server_ui_update_bg(UI *ui __unused, Integer bg) {
  @autoreleasepool {
    if (bg != -1) {
      _default_background = bg;
    }

    send_msg_packing(NvimServerMsgIdSetBackground, ^(msgpack_packer *packer) {
      msgpack_pack_int64(packer, _default_background);
    });
  }
}

static void server_ui_update_sp(UI *ui __unused, Integer sp) {
  @autoreleasepool {
    if (sp != -1) {
      _default_special = sp;
    }


    send_msg_packing(NvimServerMsgIdSetSpecial, ^(msgpack_packer *packer) {
      msgpack_pack_int64(packer, _default_special);
    });
  }
}

static void server_ui_set_title(UI *ui __unused, String title) {
  @autoreleasepool {
    if (title.size == 0) {
      return;
    }

    send_msg_packing(NvimServerMsgIdSetTitle, ^(msgpack_packer *packer) {
      msgpack_rpc_from_string(title, packer);
    });
  }
}

static void server_ui_set_icon(UI *ui __unused, String icon) {
  @autoreleasepool {
    if (icon.size == 0) {
      return;
    }

    send_msg_packing(NvimServerMsgIdSetTitle, ^(msgpack_packer *packer) {
      msgpack_rpc_from_string(icon, packer);
    });
  }
}

static void server_ui_stop(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdStop];

  let data = (ServerUiData *) ui->data;
  data->stop = true;
}

#pragma mark Public
// called by neovim

void custom_ui_start(void) {
  UI *ui = xcalloc(1, sizeof(UI));

  ui->rgb = true;
  ui->stop = server_ui_stop;
  ui->resize = server_ui_resize;
  ui->clear = server_ui_clear;
  ui->eol_clear = server_ui_eol_clear;
  ui->cursor_goto = server_ui_cursor_goto;
  ui->update_menu = server_ui_update_menu;
  ui->busy_start = server_ui_busy_start;
  ui->busy_stop = server_ui_busy_stop;
  ui->mouse_on = server_ui_mouse_on;
  ui->mouse_off = server_ui_mouse_off;
  ui->mode_info_set = server_ui_mode_info_set;
  ui->mode_change = server_ui_mode_change;
  ui->set_scroll_region = server_ui_set_scroll_region;
  ui->scroll = server_ui_scroll;
  ui->highlight_set = server_ui_highlight_set;
  ui->put = server_ui_put;
  ui->bell = server_ui_bell;
  ui->visual_bell = server_ui_visual_bell;
  ui->update_fg = server_ui_update_fg;
  ui->update_bg = server_ui_update_bg;
  ui->update_sp = server_ui_update_sp;
  ui->flush = server_ui_flush;
  ui->suspend = NULL;
  ui->set_title = server_ui_set_title;
  ui->set_icon = server_ui_set_icon;

  ui_bridge_attach(ui, server_ui_main, server_ui_scheduler);
}

void custom_ui_autocmds_groups(
    event_T event,
    char_u *fname __unused,
    char_u *fname_io __unused,
    int group __unused,
    bool force __unused,
    buf_T *buf,
    exarg_T *eap __unused
) {
  // We don't need these events in the UI (yet) and they slow down scrolling: Enable them,
  // if necessary, only after optimizing the scrolling.
  if (event == EVENT_CURSORMOVED || event == EVENT_CURSORMOVEDI) {
    return;
  }

  @autoreleasepool {
    DLOG("got event %d for file %s in group %d.", event, fname, group);

    if (event == EVENT_DIRCHANGED) {
      send_cwd();
      return;
    }

    if (event == EVENT_COLORSCHEME) {
      send_colorscheme();
      return;
    }

    if (event == EVENT_TEXTCHANGED
        || event == EVENT_TEXTCHANGEDI
        || event == EVENT_BUFWRITEPOST
        || event == EVENT_BUFLEAVE) {
      send_dirty_status();
    }

    send_msg_packing(NvimServerMsgIdAutoCommandEvent, ^(msgpack_packer *packer) {
      msgpack_pack_array(packer, 2);
      msgpack_pack_int64(packer, (NSInteger) event);
      if (buf == NULL) {
        msgpack_pack_int64(packer, -1);
      } else {
        msgpack_pack_int64(packer, (NSInteger) buf->handle);
      }
    });
  }
}

#pragma mark Other help functions

void start_neovim(NSInteger width, NSInteger height, NSArray<NSString *> *args) {
  // The caller has an @autoreleasepool.
  _initialWidth = width;
  _initialHeight = height;

  // set $VIMRUNTIME to ${RESOURCE_PATH_OF_XPC_BUNDLE}/runtime
  let bundlePath = [NSBundle bundleForClass:[NvimServer class]].bundlePath;
  let resourcesPath = [bundlePath.stringByDeletingLastPathComponent stringByAppendingPathComponent:@"Resources"];
  let runtimePath = [resourcesPath stringByAppendingPathComponent:@"runtime"];
  setenv("VIMRUNTIME", runtimePath.fileSystemRepresentation, true);

  // Set $LANG to en_US.UTF-8 such that the copied text to the system clipboard is not garbled.
  setenv("LANG", "en_US.UTF-8", true);

  uv_mutex_init(&_mutex);
  uv_cond_init(&_condition);

  uv_thread_create(&_nvim_thread, run_neovim, [args retain]); // released in run_neovim()
  DLOG("NeoVim started");

  // continue only after our UI main code for neovim has been fully initialized
  uv_mutex_lock(&_mutex);
  while (!_is_ui_launched) {
    uv_cond_wait(&_condition, &_mutex);
  }
  uv_mutex_unlock(&_mutex);

  uv_cond_destroy(&_condition);
  uv_mutex_destroy(&_mutex);

  _backspace = [[NSString alloc] initWithString:@"<BS>"];

  send_msg_packing(NvimServerMsgIdNvimReady, ^(msgpack_packer *packer) {
    if (msg_didany > 0) {
      msgpack_pack_true(packer);
    } else {
      msgpack_pack_false(packer);
    }
  });
}

#pragma mark Functions for neovim's main loop

typedef void (^async_work_block)(NSData *);

static void work_async(void **argv, async_work_block block) {
  @autoreleasepool {
    NSData *data = argv[0];
    block(data);
    [data release]; // retained in local_server_callback
  }
}

void neovim_scroll(void **argv) {
  work_async(argv, ^(NSData *data) {
    let values = (NSInteger *) data.bytes;
    int horiz = (int) values[0];
    int vert = (int) values[1];
    int row = (int) values[2];
    int column = (int) values[3];

    if (horiz == 0 && vert == 0) {
      return;
    }

    if (row < 0 || column < 0) {
      row = 0;
      column = 0;
    }

    // value > 0 => down or right
    int horizDir;
    int vertDir;
    if (horiz != 0) {
      horizDir = horiz > 0 ? MSCR_RIGHT : MSCR_LEFT;
      custom_ui_scroll(horizDir, ABS(horiz), row, column);
    }
    if (vert != 0) {
      vertDir = vert > 0 ? MSCR_DOWN : MSCR_UP;
      custom_ui_scroll(vertDir, ABS(vert), row, column);
    }

    refresh_ui_screen(VALID);
  });
}

void neovim_resize(void **argv) {
  work_async(argv, ^(NSData *data) {
    const NSInteger *values = data.bytes;
    let width = values[0];
    let height = values[1];

    set_ui_size(_server_ui_data->bridge, (int) width, (int) height);
    ui_refresh();
  });
}

void neovim_vim_input(void **argv) {
  work_async(argv, ^(NSData *data) {
    let input = [[[NSString alloc] initWithData:data
                                       encoding:NSUTF8StringEncoding] autorelease];

    if (_marked_text == nil) {
      nvim_input(vim_string_from(input));
      return;
    }

    // Handle cases like ㅎ -> arrow key: The previously marked text is the same as the finalized
    // text which should inserted. Neovim's drawing code is optimized such that it does not call
    // put in this case again, thus, we have to manually unmark the cells in the main app.
    if ([_marked_text isEqualToString:input]) {
      DLOG("unmarking text: '%s'\t now at %d:%d", input.cstr, _put_row, _put_column);
      const char *str = _marked_text.cstr;
      size_t cellCount = mb_string2cells((const char_u *) str);

      for (int i = 1; i <= cellCount; i++) {
        DLOG("unmarking at %d:%d", _put_row, _put_column - i);
        send_msg_packing(NvimServerMsgIdUnmark, ^(msgpack_packer *packer) {
          msgpack_pack_array(packer, 2);
          msgpack_pack_int64(packer, _put_row);
          msgpack_pack_int64(packer, MAX(_put_column - i, 0));
        });
      }
    }

    delete_marked_text();
    nvim_input(vim_string_from(input));
  });
}

void neovim_vim_input_marked_text(void **argv) {
  work_async(argv, ^(NSData *data) {
    let markedText = [[[NSString alloc] initWithData:data
                                            encoding:NSUTF8StringEncoding] autorelease];

    if (_marked_text == nil) {
      _marked_row = _put_row;
      _marked_column = _put_column + _marked_delta;
      DLOG(
          "marking position: %d:%d(%d + %d)", _put_row, _marked_column, _put_column, _marked_delta
      );
      _marked_delta = 0;
    } else {
      delete_marked_text();
    }

    DLOG("inserting marked text '%s' at %d:%d", markedText.cstr, _put_row, _put_column);
    insert_marked_text(markedText);
  });
}

void neovim_delete(void **argv) {
  work_async(argv, ^(NSData *data) {
    const NSInteger *values = data.bytes;
    NSInteger count = values[0];

    _marked_delta = 0;

    // Very ugly: When we want to have the Hanja for 하, Cocoa first finalizes 하, then sets
    // the Hanja as marked text. The main app will call this method when this happens,
    // thus compute how many cell we have to go backward to correctly
    // mark the will-be-soon-inserted Hanja... See also docs/notes-on-cocoa-text-input.md
    int emptyCounter = 0;
    for (int i = 0; i < count; i++) {
      _marked_delta -= 1;

      // TODO: -1 because we assume that the cursor is one cell ahead,
      // probably not always correct...
      schar_T character = ScreenLines[_put_row * screen_Rows + _put_column - i - emptyCounter - 1];
      if (character == 0x00 || character == ' ') {
        // FIXME: dunno yet, why we have to also match ' '...
        _marked_delta -= 1;
        emptyCounter += 1;
      }
    }

    DLOG("put cursor: %d:%d, count: %li, delta: %d", _put_row, _put_column, count, _marked_delta);

    for (int i = 0; i < count; i++) {
      nvim_input(vim_string_from(_backspace));
    }
  });
}

void neovim_focus_gained(void **argv) {
  work_async(argv, ^(NSData *data) {
    const bool *values = data.bytes;

    aucmd_schedule_focusgained(values[0]);
  });
}

void neovim_debug1(void **argv) {
  work_async(argv, ^(NSData *data) {
    NSLog(@"normal fg: %#08X", normal_fg);
    NSLog(@"normal bg: %#08X", normal_bg);
    NSLog(@"normal sp: %#08X", normal_sp);

    for (int i = 0; i < HLF_COUNT; i++) {
      NSLog(@"%s: %#08X", hlf_names[i], HlAttrsFromAttrCode(highlight_attr[i]).foreground);
    }
  });
}
