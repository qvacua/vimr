/**
 * Tae Won Ha - http://taewon.de - @hataewon
 * See LICENSE
 */

#import <Foundation/Foundation.h>


@class NeoVimServer;

extern NeoVimServer *_neovim_server;

extern void start_neovim();
extern void do_vim_input(NSString *input);
extern void do_delete(NSInteger count);
extern void do_force_redraw();
extern void do_resize(int width, int height);
extern void do_vim_input_marked_text(NSString *markedText);
extern void do_insert_marked_text(NSString *markedText);
