/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#include "server_log.h"

#define FileInfo CarbonFileInfo
#define Boolean CarbonBoolean

#include "server_shared_types.h"
#include "server.h"

#undef Boolean
#undef FileInfo

#include <nvim/api/private/defs.h>
#include <nvim/vim.h>
#include <nvim/fileio.h>
#include <nvim/undo.h>
#include <nvim/syntax.h>
#include <nvim/highlight.h>
#include <nvim/msgpack_rpc/helpers.h>
#include "server_ui_bridge.h"

server_ui_bridge_data_t bridge_data;

#pragma mark server_ui_bridge

static NSInteger default_foreground = 0xFF000000;
static NSInteger default_background = 0xFFFFFFFF;
static NSInteger default_special = 0xFFFF0000;

static bool are_buffers_dirty = false;

static msgpack_sbuffer flush_sbuffer;
static msgpack_packer flush_packer;

static void pack_flush_data(RenderDataType type, pack_block body);
static void pack_mode_info_dictionary(msgpack_packer *packer, Dictionary dict);
static void send_cwd(void);
static void send_dirty_status(void);
static void send_colorscheme(void);

static void server_ui_scheduler(Event event, void *d);
static void server_ui_main(UIBridgeData *bridge, UI *ui);

#pragma mark ui_bridge callbacks

static void server_ui_flush(UI *ui __unused) {
  if (flush_sbuffer.size == 0) {return;}

  CFDataRef const data = CFDataCreateWithBytesNoCopy(
      kCFAllocatorDefault,
      (const UInt8 *) flush_sbuffer.data,
      flush_sbuffer.size,
      kCFAllocatorNull
  );
  server_send_msg(NvimServerMsgIdFlush, data);
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
  server_send_msg(NvimServerMsgIdClear, NULL);
}

static void server_ui_cursor_goto(
    UI *ui __unused,
    Integer grid __unused,
    Integer row,
    Integer col
) {
  pack_flush_data(RenderDataTypeGoto, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 4);
    msgpack_pack_int64(packer, row);
    msgpack_pack_int64(packer, col);
    msgpack_pack_int64(packer, curwin->w_cursor.lnum);
    msgpack_pack_int64(packer, curwin->w_cursor.col + 1);
  });
}

static void server_ui_update_menu(UI *ui __unused) {
  server_send_msg(NvimServerMsgIdSetMenu, NULL);
}

static void server_ui_busy_start(UI *ui __unused) {
  server_send_msg(NvimServerMsgIdBusyStart, NULL);
}

static void server_ui_busy_stop(UI *ui __unused) {
  server_send_msg(NvimServerMsgIdBusyStop, NULL);
}

static void server_ui_mode_info_set(
    UI *ui __unused,
    Boolean enabled,
    Array cursor_styles
) {
  send_msg_packing(NvimServerMsgIdModeInfoSet, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 2);
    msgpack_pack_bool(packer, enabled);
    msgpack_pack_array(packer, cursor_styles.size);
    for (size_t i = 0; i < cursor_styles.size; ++i) {
      Object item = cursor_styles.items[i];
      if (item.type == kObjectTypeDictionary) {
        pack_mode_info_dictionary(packer, item.data.dictionary);
      } else {
        // this should never happen, but write nil to match the given array size
        msgpack_pack_nil(packer);
      }
    }
  });
}

static void server_ui_mode_change(UI *ui __unused, String mode_str __unused, Integer mode) {
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
  FontTrait trait = FontTraitNone;
  if (attrs.rgb_ae_attr & HL_ITALIC) {trait |= FontTraitItalic;}
  if (attrs.rgb_ae_attr & HL_BOLD) {trait |= FontTraitBold;}
  if (attrs.rgb_ae_attr & HL_UNDERLINE) {trait |= FontTraitUnderline;}
  if (attrs.rgb_ae_attr & HL_UNDERCURL) {trait |= FontTraitUndercurl;}

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

static void server_hl_group_set(UI *ui, String name, Integer id) {
}

static void server_ui_raw_line(
    UI *ui __unused,
    Integer grid __unused,
    Integer row,
    Integer startcol,
    Integer endcol,
    Integer clearcol,
    Integer clearattr,
    LineFlags flags,
    const schar_T *chunk,
    const sattr_T *attrs
) {
  const Integer count = endcol - startcol;

  pack_flush_data(RenderDataTypeRawLine, ^(msgpack_packer *packer) {
    msgpack_pack_array(packer, 7);

    msgpack_pack_int64(packer, row);
    msgpack_pack_int64(packer, startcol);
    msgpack_pack_int64(packer, endcol);
    msgpack_pack_int64(packer, clearcol);
    msgpack_pack_int64(packer, clearattr);

    msgpack_pack_array(packer, (size_t) count);
    for (Integer i = 0; i < count; i++) {msgpack_pack_cstr(packer, (const char *) chunk[i]);}
    msgpack_pack_array(packer, (size_t) count);
    for (Integer i = 0; i < count; i++) {msgpack_pack_int16(packer, attrs[i]);}
  });
}

static void server_ui_bell(UI *ui __unused) {
  server_send_msg(NvimServerMsgIdBell, NULL);
}

static void server_ui_visual_bell(UI *ui __unused) {
  server_send_msg(NvimServerMsgIdVisualBell, NULL);
}

static void server_ui_default_colors_set(
    UI *ui __unused,
    Integer rgb_fg,
    Integer rgb_bg,
    Integer rgb_sp,
    Integer cterm_fg __unused,
    Integer cterm_bg __unused
) {
  if (rgb_fg != -1) {default_foreground = rgb_fg;}
  if (rgb_bg != -1) {default_background = rgb_bg;}
  if (rgb_sp != -1) {default_special = rgb_sp;}

  send_msg_packing(
      NvimServerMsgIdDefaultColorsChanged,
      ^(msgpack_packer *packer) {
        msgpack_pack_array(packer, 3);
        msgpack_pack_int64(packer, default_foreground);
        msgpack_pack_int64(packer, default_background);
        msgpack_pack_int64(packer, default_special);
      }
  );
}

static void server_ui_set_title(UI *ui __unused, String title) {
  if (title.size == 0) {return;}

  send_msg_packing(NvimServerMsgIdSetTitle, ^(msgpack_packer *packer) {
    msgpack_rpc_from_string(title, packer);
  });
}

static void server_ui_option_set(UI *ui __unused, String name, Object value) {
  send_msg_packing(NvimServerMsgIdOptionSet, ^(msgpack_packer *packer) {
    msgpack_pack_map(packer, 1);
    msgpack_rpc_from_string(name, packer);
    msgpack_rpc_from_object(value, packer);
  });
}

static void server_ui_stop(UI *ui __unused) {
  server_send_msg(NvimServerMsgIdStop, NULL);

  server_ui_bridge_data_t *const data = ui->data;
  data->stop = true;
}

static void dummy(UI *ui __unused) {}

static void dummy2(UI *ui __unused, String icon __unused) {}

#pragma mark called by nvim

void custom_ui_start(void) {
  UI *const ui = xcalloc(1, sizeof(UI));

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
  ui->hl_group_set = server_hl_group_set;
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
    server_send_msg(NvimServerMsgIdRpcEventSubscribed, NULL);
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

#pragma mark helpers

static bool has_dirty_docs() {
  FOR_ALL_BUFFERS(buffer) {
    if (bufIsChanged(buffer)) {return true;}
  }

  return false;
}

static void pack_flush_data(RenderDataType type, pack_block body) {
  msgpack_pack_array(&flush_packer, 2);
  msgpack_pack_int64(&flush_packer, type);
  body(&flush_packer);
}

// Small utility to pack an nvim Dictionary into a msgpack_map for mode_info_set
// BEWARE: This is by no means a generic Dict -> map packer, as only String and
// Integer values are supported for now.
static void pack_mode_info_dictionary(
    msgpack_packer *packer,
    Dictionary dict
) {
  msgpack_pack_map(packer, dict.size);
  for (size_t i = 0; i < dict.size; ++i) {
    String key = dict.items[i].key;
    Object value = dict.items[i].value;
    msgpack_pack_str(packer, key.size);
    msgpack_pack_str_body(packer, key.data, key.size);
    switch (value.type) {
      case kObjectTypeInteger:
        msgpack_pack_int64(packer, value.data.integer);
        break;
      case kObjectTypeString:
        msgpack_pack_str(packer, value.data.string.size);
        msgpack_pack_str_body(packer, value.data.string.data, value.data.string.size);
        break;
      default:
        msgpack_pack_nil(packer);
        break;
    }
  }
}

static void send_dirty_status() {
  const bool new_dirty_status = has_dirty_docs();
  if (are_buffers_dirty == new_dirty_status) {return;}

  are_buffers_dirty = new_dirty_status;

  send_msg_packing(
      NvimServerMsgIdDirtyStatusChanged,
      ^(msgpack_packer *packer) {
        msgpack_pack_bool(packer, are_buffers_dirty);
      }
  );
}

static void send_cwd() {
  char_u *const temp = xmalloc(MAXPATHL);
  if (os_dirname(temp, MAXPATHL) == FAIL) {
    xfree(temp);
    server_send_msg(NvimServerMsgIdCwdChanged, NULL);
    return;
  }

  send_msg_packing(NvimServerMsgIdCwdChanged, ^(msgpack_packer *packer) {
    msgpack_pack_cstr(packer, (const char *) temp);
    xfree(temp);
  });
}

static int foreground_for(HlAttrs attrs) {
  const int mask = attrs.rgb_ae_attr;
  return mask & HL_INVERSE ? attrs.rgb_bg_color : attrs.rgb_fg_color;
}

static int background_for(HlAttrs attrs) {
  const int mask = attrs.rgb_ae_attr;
  return mask & HL_INVERSE ? attrs.rgb_fg_color : attrs.rgb_bg_color;
}

static void send_colorscheme() {
  // It seems that the highlight groupt only gets updated when the screen is
  // redrawn. Since there's a guard var, probably it's safe to call it here...
  if (need_highlight_changed) {highlight_changed();}

  const HlAttrs visualAttrs = syn_attr2entry(highlight_attr[HLF_V]);
  const HlAttrs dirAttrs = syn_attr2entry(highlight_attr[HLF_D]);

  send_msg_packing(
      NvimServerMsgIdColorSchemeChanged,
      ^(msgpack_packer *packer) {
        msgpack_pack_array(packer, 5);
        msgpack_pack_int64(packer, normal_fg);
        msgpack_pack_int64(packer, normal_bg);
        msgpack_pack_int64(packer, foreground_for(visualAttrs));
        msgpack_pack_int64(packer, background_for(visualAttrs));
        msgpack_pack_int64(packer, foreground_for(dirAttrs));
      }
  );
}

void server_set_ui_size(UIBridgeData *bridge, int width, int height) {
  bridge->ui->width = width;
  bridge->ui->height = height;
  bridge->bridge.width = width;
  bridge->bridge.height = height;
}

static void server_ui_scheduler(Event event, void *d) {
  UI *const ui = d;
  server_ui_bridge_data_t *data = ui->data;
  loop_schedule_fast(data->loop, event);
}

static void server_ui_main(UIBridgeData *bridge, UI *ui) {
  msgpack_sbuffer_init(&flush_sbuffer);
  msgpack_packer_init(&flush_packer, &flush_sbuffer, msgpack_sbuffer_write);

  Loop loop;
  loop_init(&loop, NULL);

  ui->data = &bridge_data;
  bridge_data.bridge = bridge;
  bridge_data.loop = &loop;

  server_set_ui_size(bridge, bridge_data.init_width, bridge_data.init_height);

  bridge_data.stop = false;
  CONTINUE(bridge);

  send_msg_packing(NvimServerMsgIdNvimReady, ^(msgpack_packer *packer) {
    msgpack_pack_bool(packer, msg_didany > 0);
  });

  // We have to manually trigger this to initially get the colorscheme.
  send_colorscheme();

  while (!bridge_data.stop) {loop_poll_events(&loop, -1);}

  ui_bridge_stopped(bridge);
  loop_close(&loop, false);

  server_destroy_local_port();
  server_destroy_remote_port();
  // ui is freed in ui_bridge_stop(), thus, no xfree(ui) here.

  free(msgpack_sbuffer_release(&flush_sbuffer));

  // mch_exit() of neovim will call exit(...)
}
