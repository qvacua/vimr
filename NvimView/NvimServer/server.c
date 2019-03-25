/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#include <stdlib.h>
#include <uv.h>

#define FileInfo CarbonFileInfo
#define Boolean CarbonBoolean

#include "server.h"
#include "server_log.h"

#undef FileInfo
#undef Boolean

#include <nvim/main.h>
#include <nvim/edit.h>
#include <nvim/mouse.h>
#include <nvim/screen.h>
#include <nvim/fileio.h>
#include <nvim/api/private/helpers.h>
#include <api/vim.h.generated.h>
#include <nvim/aucmd.h>
#include "server_ui_bridge.h"

#pragma mark cond_var_t
typedef struct {
  uv_mutex_t mutex;
  uv_cond_t condition;
  uint64_t timeout;
  bool posted;
} cond_var_t;

static void cond_var_init(cond_var_t *cond_var, uint64_t timeout, bool posted) {
  memset(cond_var, 0, sizeof((*cond_var)));
  (*cond_var).timeout = timeout;
  (*cond_var).posted = posted;
  uv_cond_init(&(*cond_var).condition);
  uv_mutex_init(&(*cond_var).mutex);
}

static void cond_var_destroy(cond_var_t *cond_var) {
  uv_mutex_destroy(&(*cond_var).mutex);
  uv_cond_destroy(&(*cond_var).condition);
}

#pragma mark server
static CFMessagePortRef local_port;
static CFRunLoopRef local_port_run_loop;
static uv_thread_t local_port_thread;

static CFMessagePortRef remote_port;

static uv_thread_t nvim_thread;

static const char *cfstr2cstr(CFStringRef cfstr, bool *free_bytes);

static void setenv_vimruntime(void);
static void start_nvim(void *_);
static int nvim_argc = 0;
static const char **nvim_argv;
static CFDataRef data_async(CFDataRef data, argv_callback cb);
typedef void (^async_work_block)(CFDataRef);

static void run_local_port(void *cond_var);
static CFDataRef local_port_callback(
    CFMessagePortRef local,
    SInt32 msgid,
    CFDataRef data,
    void *info
);

static String backspace;
static void scroll(void **argv);
static void resize(void **argv);
static void delete_and_input(void **argv);
static void focus_gained(void **argv);
static void ready_for_rpcevents(void **argv);
static void debug1(void **argv);
static void do_autocmd_guienter(void **argv);

// We declare nvim_main because it's not declared in any header files of neovim
extern int nvim_main(int argc, const char **argv);


void server_set_nvim_args(int argc, const char **const argv) {
  nvim_argc = argc + 1;
  nvim_argv = malloc(nvim_argc * sizeof(char *));

  nvim_argv[0] = "nvim";
  for (int i = 0; i < argc; i++) { nvim_argv[i + 1] = argv[i]; }
}

void server_init_local_port(const char *name) {
  CFStringRef name_cf = CFStringCreateWithCString(
      kCFAllocatorDefault,
      name,
      kCFStringEncodingUTF8
  );
  local_port = CFMessagePortCreateLocal(
      kCFAllocatorDefault,
      name_cf,
      local_port_callback,
      NULL,
      NULL
  );
  CFRelease(name_cf);

  cond_var_t cond_var;
  cond_var_init(&cond_var, 5, false);

  uv_thread_create(&local_port_thread, run_local_port, &cond_var);

  uv_mutex_lock(&cond_var.mutex);
  while (!cond_var.posted) {
    uv_cond_timedwait(&cond_var.condition, &cond_var.mutex, cond_var.timeout);
  }
  uv_mutex_unlock(&cond_var.mutex);

  cond_var_destroy(&cond_var);
}

void server_destroy_local_port() {
  CFRunLoopStop(local_port_run_loop);
  if (CFMessagePortIsValid(local_port)) { CFMessagePortInvalidate(local_port); }
  CFRelease(local_port);
}

void server_init_remote_port(const char *name) {
  CFStringRef name_cf = CFStringCreateWithCString(
      kCFAllocatorDefault,
      name,
      kCFStringEncodingUTF8
  );
  remote_port = CFMessagePortCreateRemote(kCFAllocatorDefault, name_cf);
  CFRelease(name_cf);
}

void server_destroy_remote_port() {
  if (CFMessagePortIsValid(remote_port)) {
    CFMessagePortInvalidate(remote_port);
  }
  CFRelease(remote_port);
}

void server_send_msg(NvimServerMsgId msgid, CFDataRef data) {
  SInt32 response_code = CFMessagePortSendRequest(
      remote_port,
      (SInt32) msgid,
      data,
      5.0,
      5.0,
      NULL,
      NULL
  );

  if (response_code == kCFMessagePortSuccess) { return; }

  os_log_error(
      logger,
      "The msg (%lu) could not be sent: %d",
      (long) msgid, response_code
  );
}

void msgpack_pack_cstr(msgpack_packer *packer, const char *cstr) {
  const size_t len = strlen(cstr);
  msgpack_pack_str(packer, len);
  msgpack_pack_str_body(packer, cstr, len);
}

void msgpack_pack_bool(msgpack_packer *packer, bool value) {
  if (value) { msgpack_pack_true(packer); }
  else { msgpack_pack_false(packer); }
}

void send_msg_packing(NvimServerMsgId msgid, pack_block body) {
  msgpack_sbuffer sbuf;
  msgpack_sbuffer_init(&sbuf);

  msgpack_packer packer;
  msgpack_packer_init(&packer, &sbuf, msgpack_sbuffer_write);

  body(&packer);

  CFDataRef const data = CFDataCreateWithBytesNoCopy(
      kCFAllocatorDefault,
      (const UInt8 *) sbuf.data,
      sbuf.size,
      kCFAllocatorNull
  );
  server_send_msg(msgid, data);
  CFRelease(data);

  msgpack_sbuffer_destroy(&sbuf);
}

static void start_nvim(void *_) {
  backspace = cstr_as_string("<BS>");

  setenv_vimruntime();

  // Set $LANG to en_US.UTF-8 such that the copied text to the system clipboard
  // is not garbled.
  setenv("LANG", "en_US.UTF-8", true);

  nvim_main(nvim_argc, nvim_argv);
}

static void setenv_vimruntime() {
  CFBundleRef main_bundle = CFBundleGetMainBundle();
  CFURLRef exe_url = CFBundleCopyBundleURL(main_bundle);

  CFURLRef bundle_url = CFURLCreateCopyDeletingLastPathComponent(
      kCFAllocatorDefault,
      exe_url
  );
  CFRelease(exe_url);

  CFURLRef rsrc_url = CFURLCreateCopyAppendingPathComponent(
      kCFAllocatorDefault,
      bundle_url,
      CFSTR("Resources"),
      true
  );
  CFRelease(bundle_url);

  CFURLRef runtime_url = CFURLCreateCopyAppendingPathComponent(
      kCFAllocatorDefault,
      rsrc_url,
      CFSTR("runtime"),
      true
  );
  CFRelease(rsrc_url);

  CFStringRef runtime_path = CFURLCopyPath(runtime_url);
  CFRelease(runtime_url);

  bool free_runtime_cstr;
  const char *runtime_cstr = cfstr2cstr(runtime_path, &free_runtime_cstr);

  setenv("VIMRUNTIME", runtime_cstr, true);

  if (free_runtime_cstr) { free((void *) runtime_cstr); }

  CFRelease(runtime_path);
}

static CFDataRef data_async(CFDataRef data, argv_callback cb) {
  loop_schedule(&main_loop, event_create(cb, 3, data));
  return NULL;
}

static void work_async(void **argv, async_work_block body) {
  CFDataRef data = argv[0];
  body(data);
  CFRelease(data); // retained in local_port_callback
}

static CFDataRef local_port_callback(
    CFMessagePortRef local __unused,
    SInt32 msgid,
    CFDataRef data,
    void *info __unused
) {
  if (data != NULL) {
    CFRetain(data); // released in work_async (or in the case block below)
  }

  switch (msgid) {

    case NvimBridgeMsgIdAgentReady: {
      const NSInteger *const values = (NSInteger *) CFDataGetBytePtr(data);
      bridge_data.init_width = (int) values[0];
      bridge_data.init_height = (int) values[1];
      CFRelease(data);

      uv_thread_create(&nvim_thread, start_nvim, NULL);
      return NULL;
    }

    case NvimBridgeMsgIdScroll:
      return data_async(data, scroll);

    case NvimBridgeMsgIdResize:
      return data_async(data, resize);

    case NvimBridgeMsgIdDeleteInput:
      return data_async(data, delete_and_input);

    case NvimBridgeMsgIdFocusGained:
      return data_async(data, focus_gained);

    case NvimBridgeMsgIdReadyForRpcEvents:
      return data_async(data, ready_for_rpcevents);

    case NvimBridgeMsgIdDebug1:
      return data_async(data, debug1);

    default:
      os_log(logger, "msgid received: %{public}ld", (long) msgid);
      if (data != NULL) { CFRelease(data); }
      return NULL;

  }
}

static void run_local_port(void *arg) {
  local_port_run_loop = CFRunLoopGetCurrent();
  CFRunLoopSourceRef const run_loop_src = CFMessagePortCreateRunLoopSource(
      kCFAllocatorDefault,
      local_port,
      0
  );
  CFRunLoopAddSource(local_port_run_loop, run_loop_src, kCFRunLoopCommonModes);
  CFRelease(run_loop_src);

  cond_var_t *cond_var = (cond_var_t *) arg;

  uv_mutex_lock(&cond_var->mutex);
  cond_var->posted = true;
  uv_cond_signal(&cond_var->condition);
  uv_mutex_unlock(&cond_var->mutex);

  CFRunLoopRun();
}

static const char *cfstr2cstr(CFStringRef cfstr, bool *free_bytes) {
  *free_bytes = false;

  const char *cptr = CFStringGetCStringPtr(cfstr, kCFStringEncodingUTF8);
  if (cptr != NULL) { return cptr; }

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

  if (converted == 0 || out_len == 0) { return NULL; }

  const char *result = malloc((size_t) (out_len + 1));
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
    free((void *) result);
    return NULL;
  }

  *free_bytes = true;
  return result;
}

#pragma mark local message port callbacks

static void scroll(void **argv) {
  work_async(argv, ^(CFDataRef data) {
    const NSInteger *const values
        = (const NSInteger *const) CFDataGetBytePtr(data);
    const int horiz = (int) values[0];
    const int vert = (int) values[1];
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
      custom_ui_scroll(horizDir, abs(horiz), row, column);
    }
    if (vert != 0) {
      vertDir = vert > 0 ? MSCR_DOWN : MSCR_UP;
      custom_ui_scroll(vertDir, abs(vert), row, column);
    }

    update_screen(VALID);
    setcursor();
    ui_flush();
  });
}

static void resize(void **argv) {
  work_async(argv, ^(CFDataRef data) {
    const NSInteger *const values
        = (const NSInteger *const) CFDataGetBytePtr(data);
    const NSInteger width = values[0];
    const NSInteger height = values[1];

    server_set_ui_size(bridge_data.bridge, (int) width, (int) height);
    ui_refresh();
  });
}

static void delete_and_input(void **argv) {
  work_async(argv, ^(CFDataRef data) {
    const NSInteger *const values
        = (const NSInteger *const) CFDataGetBytePtr(data);
    const NSInteger count = values[0];
    for (int i = 0; i < count; i++) {
      nvim_input(backspace);
    }

    const char *stringPtr = (const char *) (values + 1);
    String string = cbuf_to_string(
        stringPtr,
        CFDataGetLength(data) - sizeof(NSInteger)
    );
    nvim_input(string);
    api_free_string(string);
  });
}

static void focus_gained(void **argv) {
  work_async(argv, ^(CFDataRef data) {
    const bool *values = (const bool *) CFDataGetBytePtr(data);

    aucmd_schedule_focusgained(values[0]);
  });
}

static void ready_for_rpcevents(void **argv) {
  work_async(argv, ^(CFDataRef data) {
    loop_schedule_deferred(&main_loop, event_create(do_autocmd_guienter, 0));
  });
}

static void debug1(void **argv) {
  work_async(argv, ^(CFDataRef data) {
    // yet noop
    os_log(logger, "debug1");
  });
}

static void do_autocmd_guienter(void **argv) {
  static bool recursive = false;

  if (recursive) {
    return;  // disallow recursion
  }
  recursive = true;
  apply_autocmds(EVENT_GUIENTER, NULL, NULL, false, curbuf);
  recursive = false;
}
