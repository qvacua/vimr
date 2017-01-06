/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

@import Foundation;


@class NeoVimServer;

extern NeoVimServer *_neovim_server;

extern void server_start_neovim();
extern void server_vim_command(NSString *input);
extern void server_vim_input(NSString *input);
extern void server_delete(NSInteger count);
extern void server_vim_input_marked_text(NSString *markedText);
extern void server_quit();

extern void neovim_select_window(void **argv);
extern void neovim_tabs(void **argv);
extern void neovim_buffers(void **argv);
extern void neovim_vim_command_output(void **argv);
extern void neovim_set_bool_option(void **argv);
extern void neovim_get_bool_option(void **argv);
extern void neovim_escaped_filenames(void **argv);
extern void neovim_has_dirty_docs(void **argv);
extern void neovim_resize(void **argv);
