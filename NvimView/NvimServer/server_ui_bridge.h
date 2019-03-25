/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#ifndef NVIMSERVER_SERVER_UI_BRIDGE_H
#define NVIMSERVER_SERVER_UI_BRIDGE_H

// FileInfo and Boolean are #defined by Carbon and NeoVim:
// Since we don't need the Carbon versions of them, we rename
// them.
#define FileInfo CarbonFileInfo
#define Boolean CarbonBoolean

#include <nvim/api/private/defs.h>
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
