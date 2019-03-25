/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#ifndef NVIMSERVER_SERVER_H
#define NVIMSERVER_SERVER_H

#include <msgpack.h>
#include "server_shared_types.h"

void server_set_nvim_args(int argc, const char **const args);

void server_init_local_port(const char *name);
void server_destroy_local_port(void);

void server_init_remote_port(const char *name);
void server_destroy_remote_port(void);

void server_send_msg(NvimServerMsgId msgId, CFDataRef data);

typedef void (^pack_block)(msgpack_packer *packer);
void send_msg_packing(NvimServerMsgId msgid, pack_block body);
void msgpack_pack_bool(msgpack_packer *packer, bool value);
void msgpack_pack_cstr(msgpack_packer *packer, const char *cstr);

#endif // NVIMSERVER_SERVER_H
