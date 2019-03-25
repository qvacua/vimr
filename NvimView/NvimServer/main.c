/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#include "server_log.h"
#include "server.h"

os_log_t logger;

static void observe_parent_termination(void);

int main(int argc, const char *argv[]) {
  logger = os_log_create("com.qvacua.NvimServer", "server");
  observe_parent_termination();

  const int nvim_argc = argc - 3;
  const char **nvim_args = &argv[3];
  const char *remote_port_name = argv[1];
  const char *local_port_name = argv[2];

  server_set_nvim_args(nvim_argc, nvim_argc == 0 ? NULL : nvim_args);
  server_init_local_port(local_port_name);
  server_init_remote_port(remote_port_name);

  server_send_msg(NvimServerMsgIdServerReady, NULL);

  os_log_debug(
      logger,
      "Started NvimServer '%s' and connected it with GUI '%s'.",
      local_port_name, remote_port_name
  );
  CFRunLoopRun();
  os_log_debug(logger, "NvimServer exiting.");

  return 0;
}

static void observe_parent_termination() {
  const pid_t parent_pid = getppid();

  const dispatch_queue_t queue = dispatch_get_global_queue(
      DISPATCH_QUEUE_PRIORITY_DEFAULT, 0
  );
  dispatch_source_t source = dispatch_source_create(
      DISPATCH_SOURCE_TYPE_PROC,
      (uintptr_t) parent_pid,
      DISPATCH_PROC_EXIT,
      queue
  );

  if (source == NULL) {
    os_log_error(logger, "No parent process monitoring...");
    return;
  }

  dispatch_source_set_event_handler(source, ^{
    os_log_fault(logger, "Exiting neovim server due to parent termination.");
    CFRunLoopStop(CFRunLoopGetMain());
    dispatch_source_cancel(source);
  });

  dispatch_resume(source);
}
