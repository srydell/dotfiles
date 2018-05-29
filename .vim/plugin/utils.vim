" Disable undo file when in tmp
" (so no passwords are accidentally saved in undodir)
augroup noUndoTempFiles
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
                \   q :cclose<CR>:lclose<CR>
	" If there is only a quickfix type buffer left open, close it
    autocmd BufEnter * if (winnr('$') == 1 && &buftype ==# 'quickfix' ) |
                \   bd|
                \   q | endif
augroup END
