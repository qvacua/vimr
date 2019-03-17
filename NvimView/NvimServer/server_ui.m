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

#import <nvim/main.h>
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
#import <nvim/highlight.h>
#import <nvim/msgpack_rpc/helpers.h>


#define let __auto_type const
#define var __auto_type


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

static ServerUiData *_server_ui_data;

static NSString *_backspace = @"<BS>";

static bool _dirty = false;

static NSInteger _initialWidth = 30;
static NSInteger _initialHeight = 15;

static msgpack_sbuffer flush_sbuffer;
static msgpack_packer flush_packer;


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

static void msgpack_pack_cstr(msgpack_packer *packer, const char *cstr) {
  size_t len = strlen(cstr);
  msgpack_pack_str(packer, len);
  msgpack_pack_str_body(packer, cstr, len);
}

static void msgpack_pack_bool(msgpack_packer *packer, bool value) {
  if (value) {
    msgpack_pack_true(packer);
  } else {
    msgpack_pack_false(packer);
  }
}

typedef void (^pack_block)(msgpack_packer *packer);

static void send_msg_packing(NvimServerMsgId msgid, pack_block body) {
  msgpack_sbuffer sbuf;
  msgpack_sbuffer_init(&sbuf);

  msgpack_packer packer;
  msgpack_packer_init(&packer, &sbuf, msgpack_sbuffer_write);

  body(&packer);

  let data = CFDataCreateWithBytesNoCopy(
      kCFAllocatorDefault,
      (const UInt8 *) sbuf.data,
      sbuf.size,
      kCFAllocatorNull
  );
  [_neovim_server sendMessageWithId:msgid data:data];
  CFRelease(data);

  msgpack_sbuffer_destroy(&sbuf);
}

static void pack_flush_data(RenderDataType type, pack_block body) {
  msgpack_pack_array(&flush_packer, 2);
  msgpack_pack_int64(&flush_packer, type);
  body(&flush_packer);
}

static void send_dirty_status() {
  var new_dirty_status = has_dirty_docs();
  if (_dirty == new_dirty_status) {
    return;
  }

  _dirty = new_dirty_status;

  send_msg_packing(
      NvimServerMsgIdDirtyStatusChanged,
      ^(msgpack_packer *packer) {
        msgpack_pack_bool(packer, _dirty);
      });
}

static void send_cwd() {
  var temp = xmalloc(MAXPATHL);
  if (os_dirname(temp, MAXPATHL) == FAIL) {
    xfree(temp);
    [_neovim_server sendMessageWithId:NvimServerMsgIdCwdChanged];
  }

  send_msg_packing(NvimServerMsgIdCwdChanged, ^(msgpack_packer *packer) {
    msgpack_pack_cstr(packer, temp);
    xfree(temp);
  });
}

static HlAttrs HlAttrsFromAttrCode(int attr_code) {
  HlAttrs aep = syn_attr2entry(attr_code);
  HlAttrs rgb_attrs = aep;
  return rgb_attrs;
}

static int foreground_for(HlAttrs attrs) {
  int mask = attrs.rgb_ae_attr;
  return mask & HL_INVERSE ? attrs.rgb_bg_color : attrs.rgb_fg_color;
}

static int background_for(HlAttrs attrs) {
  int mask = attrs.rgb_ae_attr;
  return mask & HL_INVERSE ? attrs.rgb_fg_color : attrs.rgb_bg_color;
}

static void send_colorscheme() {
  // It seems that the highlight groupt only gets updated when the screen is
  // redrawn. Since there's a guard var, probably it's safe to call it here...
  if (need_highlight_changed) {
    highlight_changed();
  }

  HlAttrs visualAttrs = HlAttrsFromAttrCode(highlight_attr[HLF_V]);
  HlAttrs dirAttrs = HlAttrsFromAttrCode(highlight_attr[HLF_D]);

  send_msg_packing(
      NvimServerMsgIdColorSchemeChanged,
      ^(msgpack_packer *packer) {
        msgpack_pack_array(packer, 5);
        msgpack_pack_int64(packer, normal_fg);
        msgpack_pack_int64(packer, normal_bg);
        msgpack_pack_int64(packer, foreground_for(visualAttrs));
        msgpack_pack_int64(packer, background_for(visualAttrs));
        msgpack_pack_int64(packer, foreground_for(dirAttrs));
      });
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
      char *str = (char *) nvimArgs[(NSUInteger) i].cstr;
      argv[i + 1] = malloc(strlen(str) + 1);
      strcpy(argv[i + 1], str);
    }

    [nvimArgs release]; // retained in start_neovim()
  }

  nvim_main(argc, argv);

  for (var i = 0; i < argc - 1; i++) {
    free(argv[i + 1]);
  }
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
  msgpack_sbuffer_init(&flush_sbuffer);
  msgpack_packer_init(&flush_packer, &flush_sbuffer, msgpack_sbuffer_write);

  Loop loop;
  loop_init(&loop, NULL);

  _server_ui_data = xcalloc(1, sizeof(ServerUiData));
  ui->data = _server_ui_data;
  _server_ui_data->bridge = bridge;
  _server_ui_data->loop = &loop;

  set_ui_size(bridge, (int) _initialWidth, (int) _initialHeight);

  _server_ui_data->stop = false;
  CONTINUE(bridge);

  send_msg_packing(NvimServerMsgIdNvimReady, ^(msgpack_packer *packer) {
    msgpack_pack_bool(packer, msg_didany > 0);
  });

  // We have to manually trigger this to initially get the colorscheme.
  send_colorscheme();

  while (!_server_ui_data->stop) {
    loop_poll_events(&loop, -1);
  }

  ui_bridge_stopped(bridge);
  loop_close(&loop, false);

  xfree(_server_ui_data);
  xfree(ui);

  free(msgpack_sbuffer_release(&flush_sbuffer));
}

#pragma mark NeoVim's UI callbacks

static void server_ui_flush(UI *ui __unused) {
  if (flush_sbuffer.size == 0) {
    return;
  }

  let data = CFDataCreateWithBytesNoCopy(
      kCFAllocatorDefault,
      (const UInt8 *) flush_sbuffer.data,
      flush_sbuffer.size,
      kCFAllocatorNull
  );
  [_neovim_server sendMessageWithId:NvimServerMsgIdFlush data:data];
  CFRelease(data);

  free(msgpack_sbuffer_release(&flush_sbuffer));
  msgpack_packer_init(&flush_packer, &flush_sbuffer, msgpack_sbuffer_write);
}

static void server_ui_grid_resize(
    UI *ui __unused, Integer grid __unused, Integer width, Integer height
) {
  server_ui_flush(NULL);

  send_msg_packing(NvimServerMsgIdResize, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 2);
    msgpack_pack_int64(packer, width);
    msgpack_pack_int64(packer, height);
  });
}

static void server_ui_grid_clear(UI *ui __unused, Integer grid __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdClear];
}

static void server_ui_cursor_goto(
    UI *ui __unused, Integer grid __unused, Integer row, Integer col
) {
  pack_flush_data(RenderDataTypeGoto, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 2);
    msgpack_pack_int64(packer, row);
    msgpack_pack_int64(packer, col);
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

static void server_ui_mode_info_set(
    UI *ui __unused, Boolean enabled __unused, Array cursor_styles __unused
) {
  // yet noop
}

static void server_ui_mode_change(
    UI *ui __unused, String mode_str __unused, Integer mode
) {
  send_msg_packing(NvimServerMsgIdModeChange, ^(msgpack_packer *packer) {
    msgpack_pack_int64(packer, mode);
  });
}

static void server_ui_grid_scroll(
    UI *ui __unused,
    Integer grid __unused,
    Integer top,
    Integer bot,
    Integer left,
    Integer right,
    Integer rows,
    Integer cols
) {
  pack_flush_data(RenderDataTypeScroll, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 6);
    msgpack_pack_int64(packer, top);
    msgpack_pack_int64(packer, bot);
    msgpack_pack_int64(packer, left);
    msgpack_pack_int64(packer, right);
    msgpack_pack_int64(packer, rows);
    msgpack_pack_int64(packer, cols);
  });
}

static void server_ui_hl_attr_define(
    UI *ui __unused,
    Integer id, HlAttrs attrs,
    HlAttrs cterm_attrs __unused,
    Array info __unused
) {
  var trait = FontTraitNone;
  if (attrs.rgb_ae_attr & HL_ITALIC) {
    trait |= FontTraitItalic;
  }
  if (attrs.rgb_ae_attr & HL_BOLD) {
    trait |= FontTraitBold;
  }
  if (attrs.rgb_ae_attr & HL_UNDERLINE) {
    trait |= FontTraitUnderline;
  }
  if (attrs.rgb_ae_attr & HL_UNDERCURL) {
    trait |= FontTraitUndercurl;
  }

  send_msg_packing(NvimServerMsgIdHighlightAttrs, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 6);
    msgpack_pack_int64(packer, id);
    msgpack_pack_uint64(packer, trait);
    msgpack_pack_int32(packer, attrs.rgb_fg_color);
    msgpack_pack_int32(packer, attrs.rgb_bg_color);
    msgpack_pack_int32(packer, attrs.rgb_sp_color);
    msgpack_pack_bool(packer, (bool) (attrs.rgb_ae_attr & HL_INVERSE));
  });
}

static void server_ui_raw_line(
    UI *ui __unused,
    Integer grid __unused,
    Integer row,
    Integer startcol,
    Integer endcol,
    Integer clearcol,
    Integer clearattr,
    Boolean wrap,
    const schar_T *chunk,
    const sattr_T *attrs
) {
  Integer count = endcol - startcol;

  pack_flush_data(RenderDataTypeRawLine, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 7);

    msgpack_pack_int64(packer, row);
    msgpack_pack_int64(packer, startcol);
    msgpack_pack_int64(packer, endcol);
    msgpack_pack_int64(packer, clearcol);
    msgpack_pack_int64(packer, clearattr);

    msgpack_pack_array(packer, (size_t) count);
    for (Integer i = 0; i < count; i++) {
      msgpack_pack_cstr(packer, (const char *) chunk[i]);
    }
    msgpack_pack_array(packer, (size_t) count);
    for (Integer i = 0; i < count; i++) {
      msgpack_pack_int16(packer, attrs[i]);
    }
  });
}

static void server_ui_bell(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdBell];
}

static void server_ui_visual_bell(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdVisualBell];
}

static void server_ui_default_colors_set(
    UI *ui __unused,
    Integer rgb_fg,
    Integer rgb_bg,
    Integer rgb_sp,
    Integer cterm_fg __unused,
    Integer cterm_bg __unused
) {
  if (rgb_fg != -1) {
    _default_foreground = rgb_fg;
  }

  if (rgb_bg != -1) {
    _default_background = rgb_bg;
  }

  if (rgb_sp != -1) {
    _default_special = rgb_sp;
  }

  send_msg_packing(
      NvimServerMsgIdDefaultColorsChanged,
      ^(msgpack_packer *packer) {
        msgpack_pack_array(packer, 3);
        msgpack_pack_int64(packer, _default_foreground);
        msgpack_pack_int64(packer, _default_background);
        msgpack_pack_int64(packer, _default_special);
      });
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

static void server_ui_option_set(UI *ui __unused, String name, Object value) {
  send_msg_packing(NvimServerMsgIdOptionSet, ^(msgpack_packer *packer) {
    msgpack_pack_map(packer, 1);
    msgpack_rpc_from_string(name, packer);
    msgpack_rpc_from_object(value, packer);
  });
}

static void server_ui_stop(UI *ui __unused) {
  [_neovim_server sendMessageWithId:NvimServerMsgIdStop];

  let data = (ServerUiData *) ui->data;
  data->stop = true;
}

static void dummy(UI *ui __unused) {

}

static void dummy2(UI *ui __unused, String icon) {

}

#pragma mark Public
// called by neovim

void custom_ui_start(void) {
  UI *ui = xcalloc(1, sizeof(UI));

  memset(ui->ui_ext, 0, sizeof(ui->ui_ext));
  ui->ui_ext[kUILinegrid] = true;

  ui->rgb = true;
  ui->stop = server_ui_stop;
  ui->grid_resize = server_ui_grid_resize;
  ui->grid_clear = server_ui_grid_clear;
  ui->grid_cursor_goto = server_ui_cursor_goto;
  ui->update_menu = server_ui_update_menu;
  ui->busy_start = server_ui_busy_start;
  ui->busy_stop = server_ui_busy_stop;
  ui->mouse_on = dummy;
  ui->mouse_off = dummy;
  ui->mode_info_set = server_ui_mode_info_set;
  ui->mode_change = server_ui_mode_change;
  ui->grid_scroll = server_ui_grid_scroll;
  ui->hl_attr_define = server_ui_hl_attr_define;
  ui->default_colors_set = server_ui_default_colors_set;
  ui->raw_line = server_ui_raw_line;
  ui->bell = server_ui_bell;
  ui->visual_bell = server_ui_visual_bell;
  ui->flush = server_ui_flush;
  ui->suspend = dummy;
  ui->set_title = server_ui_set_title;
  ui->set_icon = dummy2;
  ui->option_set = server_ui_option_set;

  ui_bridge_attach(ui, server_ui_main, server_ui_scheduler);
}

void custom_ui_rpcevent_subscribed() {
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    [_neovim_server sendMessageWithId:NvimServerMsgIdRpcEventSubscribed
                                 data:NULL];
  });
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
  switch (event) {
    case EVENT_BUFENTER:
    case EVENT_BUFLEAVE:
    case EVENT_BUFWINENTER:
    case EVENT_BUFWINLEAVE:
    case EVENT_BUFWRITEPOST:
    case EVENT_COLORSCHEME:
    case EVENT_DIRCHANGED:
    case EVENT_TABENTER:
    case EVENT_TEXTCHANGED:
    case EVENT_TEXTCHANGEDI:
    case EVENT_VIMENTER:
    case EVENT_GUIENTER:
      break;

    default:
      return;
  }

  @autoreleasepool {
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

    send_msg_packing(
        NvimServerMsgIdAutoCommandEvent,
        ^(msgpack_packer *packer) {
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

void start_neovim(
    NSInteger width, NSInteger height, NSArray<NSString *> *args
) {
  // The caller has an @autoreleasepool.
  _initialWidth = width;
  _initialHeight = height;

  // set $VIMRUNTIME to ${RESOURCE_PATH_OF_XPC_BUNDLE}/runtime
  let bundlePath = [NSBundle bundleForClass:[NvimServer class]].bundlePath;
  let resourcesPath = [bundlePath.stringByDeletingLastPathComponent
      stringByAppendingPathComponent:@"Resources"];
  let runtimePath = [resourcesPath stringByAppendingPathComponent:@"runtime"];
  setenv("VIMRUNTIME", runtimePath.fileSystemRepresentation, true);

  // Set $LANG to en_US.UTF-8 such that the copied text to the system clipboard
  // is not garbled.
  setenv("LANG", "en_US.UTF-8", true);

  // released in run_neovim()
  uv_thread_create(&_nvim_thread, run_neovim, [args retain]);
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
    let input = [[NSString alloc] initWithData:data
                                      encoding:NSUTF8StringEncoding];

    nvim_input(vim_string_from(input));
    [input release];
  });
}

void neovim_delete_and_input(void **argv) {
  work_async(argv, ^(NSData *data) {
    const NSInteger *values = data.bytes;
    NSInteger count = values[0];
    for (int i = 0; i < count; i++) {
      nvim_input(vim_string_from(_backspace));
    }

    void *stringPtr = (void *) (values + 1);
    let string = [[NSString alloc] initWithBytes:stringPtr
                                          length:data.length - sizeof(NSInteger)
                                        encoding:NSUTF8StringEncoding];
    nvim_input(vim_string_from(string));
    [string release];
  });
}

static void do_autocmd_guienter() {
  static bool recursive = false;

  if (recursive) {
    return;  // disallow recursion
  }
  recursive = true;
  apply_autocmds(EVENT_GUIENTER, NULL, NULL, false, curbuf);
  recursive = false;
}

static void guienter_event(void **argv __unused) {
  do_autocmd_guienter();
}

static void aucmd_schedule_guienter() {
  loop_schedule_deferred(&main_loop, event_create(guienter_event, 0));
}

void neovim_focus_gained(void **argv) {
  work_async(argv, ^(NSData *data) {
    const bool *values = data.bytes;

    aucmd_schedule_focusgained(values[0]);
  });
}

void neovim_ready_for_rpcevents(void **argv) {
  work_async(argv, ^(NSData *data) {
    aucmd_schedule_guienter();
  });
}

void neovim_debug1(void **argv) {
  work_async(argv, ^(NSData *data) {
    // yet noop
    os_log(glog, "debug1");
  });
}
