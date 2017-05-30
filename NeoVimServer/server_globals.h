/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;


@class NeoVimServer;

extern NeoVimServer *_neovim_server;
extern CFRunLoopRef _mainRunLoop;

extern void start_neovim();
extern void quit_neovim();

extern void neovim_select_window(void **argv);
extern void neovim_scroll(void **argv);
extern void neovim_tabs(void **argv);
extern void neovim_buffers(void **argv);
extern void neovim_vim_command_output(void **argv);
extern void neovim_set_bool_option(void **argv);
extern void neovim_get_bool_option(void **argv);
extern void neovim_escaped_filenames(void **argv);
extern void neovim_has_dirty_docs(void **argv);
extern void neovim_resize(void **argv);
extern void neovim_vim_command(void **argv);

extern void neovim_vim_input(void **argv);
extern void neovim_vim_input_marked_text(void **argv);
extern void neovim_delete(void **argv);

extern void neovim_pwd(void **argv);

extern void neovim_cursor_goto(void **argv);
