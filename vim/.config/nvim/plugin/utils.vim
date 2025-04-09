if exists('g:loaded_srydell_utils')
  finish
endif
let g:loaded_srydell_utils = 1

" q is close quickfix/locationlist buffers
" Autoclose quickfix buffer if it's the only one available
augroup quick_and_loc_list_autoclose
  autocmd!
  " Bind q to close the window if it is a quickfix- or a location list
  " NOTE: Both quickfix and location list window have buftype 'quickfix'
  autocmd BufWinEnter quickfix nnoremap <silent> <buffer>
        \ q :cclose<CR>:lclose<CR>
augroup END

" Resize on window changed (Useful when opening new panes in tmux)
augroup resize_window_on_change
  autocmd!
  autocmd VimResized * :wincmd =
augroup END
