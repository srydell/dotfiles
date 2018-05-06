" Disable undo file when in tmp
" (so no passwords are accidentally saved in undodir)
augroup noUndoTempFiles
	autocmd!
	autocmd BufWritePre /tmp/* setlocal noundofile
augroup END
