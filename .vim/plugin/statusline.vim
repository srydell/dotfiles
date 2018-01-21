" This file builds everything in the statusbar. It is sourced in ~/.vimrc

" Enable statusline
set laststatus=2

" --- Statusline ---
" Path to file
set statusline=%f

" Separator
set statusline+=\ -\

" Label
set statusline+=FileType:
" Filetype of the file
set statusline+=%y

" Switch to the right side
set statusline+=%=

" Check session tracking
set statusline+=%{ObsessionStatus()}

" Current line
set statusline+=%l
" Separator
set statusline+=/
" Total lines
set statusline+=%L
