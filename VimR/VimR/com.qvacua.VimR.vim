function! s:VimRMakeSessionTemporary() abort
	call rpcnotify(0, 'com.qvacua.vimr.rpc-events.make-session-temporary')
endfunction
command! -nargs=0 VimRMakeSessionTemporary call s:VimRMakeSessionTemporary(<args>)

function! s:VimRMaximizeWindow() abort
	call rpcnotify(0, 'com.qvacua.vimr.rpc-events.maximize-window')
endfunction
command! -nargs=0 VimRMaximizeWindow call s:VimRMaximizeWindow(<args>)

" -1: hide, 0: toggle, 1: show
function! s:VimRToggleTools(value) abort
	call rpcnotify(0, 'com.qvacua.vimr.rpc-events.toggle-tools', a:value)
endfunction
command! -nargs=0 VimRHideTools call s:VimRToggleTools(-1)
command! -nargs=0 VimRToggleTools call s:VimRToggleTools(0)
command! -nargs=0 VimRShowTools call s:VimRToggleTools(1)

" -1: hide, 0: toggle, 1: show
function! s:VimRToggleToolButtons(value) abort
	call rpcnotify(0, 'com.qvacua.vimr.rpc-events.toggle-tool-buttons', a:value)
endfunction
command! -nargs=0 VimRHideToolButtons call s:VimRToggleToolButtons(-1)
command! -nargs=0 VimRToggleToolButtons call s:VimRToggleToolButtons(0)
command! -nargs=0 VimRShowToolButtons call s:VimRToggleToolButtons(1)

function! s:VimRToggleFullscreen() abort
	call rpcnotify(0, 'com.qvacua.vimr.rpc-events.toggle-fullscreen')
endfunction
command! -nargs=0 VimRToggleFullscreen call s:VimRToggleFullscreen(<args>)
