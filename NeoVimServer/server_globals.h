/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;


@class NeoVimServer;

extern NeoVimServer *_neovim_server;
extern CFRunLoopRef _mainRunLoop;

extern void start_neovim(NSInteger width, NSInteger height, NSArray<NSString *> *args);

extern void neovim_scroll(void **argv);
extern void neovim_escaped_filenames(void **argv);

extern void neovim_vim_input(void **argv);
extern void neovim_vim_input_marked_text(void **argv);
extern void neovim_delete(void **argv);

extern void neovim_pwd(void **argv);

extern void neovim_focus_gained(void **argv);

extern void neovim_debug1(void **argv);
