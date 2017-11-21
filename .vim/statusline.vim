" This file builds everything in the statusbar. It is sourced in ~/.vimrc

" Enable statusline
set laststatus=2

" Define the statusline
set statusline=%f	" Path to file
set statusline+=\ -\ 	" Separator
set statusline+=FileType:	" Label
set statusline+=%y	" Filetype of the file
set statusline+=%=	" Switch to the right side
set statusline+=%l	" Current line
set statusline+=/ 	" Separator
set statusline+=%L	" Total lines
