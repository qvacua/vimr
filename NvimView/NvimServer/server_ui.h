/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@class NvimServer;

extern NvimServer *_neovim_server;

extern void start_neovim(NSInteger width, NSInteger height, NSArray<NSString *> *args);

extern void neovim_scroll(void **argv);
extern void neovim_resize(void **argv);

extern void neovim_vim_input(void **argv);
extern void neovim_delete_and_input(void **argv);

extern void neovim_focus_gained(void **argv);

extern void neovim_debug1(void **argv);
