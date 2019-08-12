" Enable statusline
setlocal laststatus=2

" --- Statusline ---
" Path to file
setlocal statusline=%f

" Separator
setlocal statusline+=\ -\ 

" Label
" Filetype of the file
setlocal statusline+=%y

" Switch to the right side
setlocal statusline+=%=

" Current line
setlocal statusline+=%l
" Separator
setlocal statusline+=/
" Total lines
setlocal statusline+=%L
