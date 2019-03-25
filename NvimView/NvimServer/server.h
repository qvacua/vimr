/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#ifndef NVIMSERVER_SERVER_H
#define NVIMSERVER_SERVER_H

#include <CoreFoundation/CoreFoundation.h>
#include "server_shared_types.h"

void server_set_nvim_args(int argc, const char **const args);

void server_init_local_port(const char *name);
void server_destroy_local_port(void);

void server_init_remote_port(const char *name);
void server_destroy_remote_port(void);

void server_send_msg(NvimServerMsgId msgId, CFDataRef data);

#endif // NVIMSERVER_SERVER_H
