if exists('g:loaded_plugin_utils')
  finish
endif
let g:loaded_plugin_utils = 1

" Disable undo file when in tmp
" (so no passwords are accidentally saved in undodir)
augroup no_undo_temp_files
  autocmd!
  autocmd BufWritePre /tmp/* setlocal noundofile
augroup END

" q is close quickfix/locationlist buffers
" Autoclose quickfix buffer if it's the only one available
augroup quick_and_loc_list_autoclose
  autocmd!
  " Bind q to close the window if it is a quickfix- or a location list
  " NOTE: Both quickfix and location list window have buftype 'quickfix'
  autocmd BufWinEnter quickfix nnoremap <silent> <buffer>
        \ q :cclose<CR>:lclose<CR>
  " If there is only a quickfix type buffer left open, close it
  autocmd BufEnter * if (winnr('$') == 1 && &buftype ==# 'quickfix' ) |
        \   bd|
        \   q | endif
augroup END

" Resize on window changed (Useful when opening new panes in tmux)
augroup resize_window_on_change
  autocmd!
  autocmd VimResized * :wincmd =
augroup END
