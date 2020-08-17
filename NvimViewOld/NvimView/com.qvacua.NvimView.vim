set mouse=a
set title

autocmd VimEnter,ColorScheme * :highlight default VimrDefaultCursor gui=reverse guibg=NONE guifg=NONE
set guicursor=a:block-VimrDefaultCursor
autocmd VimEnter,ColorScheme * :highlight default VimrInsertCursor guibg=fg
set guicursor=i:ver25-VimrInsertCursor
