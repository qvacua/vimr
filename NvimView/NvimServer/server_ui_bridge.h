/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#ifndef NVIMSERVER_SERVER_UI_BRIDGE_H
#define NVIMSERVER_SERVER_UI_BRIDGE_H

#include <nvim/ui_bridge.h>

typedef struct {
  UIBridgeData *bridge;
  Loop *loop;

  bool stop;

  int init_width;
  int init_height;
} server_ui_bridge_data_t;

extern server_ui_bridge_data_t bridge_data;

void server_set_ui_size(UIBridgeData *bridge, int width, int height);

#endif // NVIMSERVER_SERVER_UI_BRIDGE_H
