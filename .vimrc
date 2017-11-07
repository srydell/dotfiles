" Package manager
source ~/.vim/packages.vim

let g:UltiSnipsSnippetDirectories=["~/.vim/UltiSnips", "UltiSnips"]
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"

let g:UltisnipsEditSplit="vertical"
let g:UltisnipsUsePythonVersion=3

" Enable filetype
filetype on
filetype plugin indent on

" Enable syntax
syntax enable

" Colorscheme
set background=dark
let g:gruvbox_contrast_dark=1
silent! colorscheme gruvbox

" Set mapleader
let mapleader="-"
let maplocalleader="-"

" Make it easier to see tabs and newlines
set list
set listchars=tab:▸\ ,eol:¬

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

" Show absolute current row and relative rows from that
set number
set relativenumber

" No swap files
set noswapfile

" Show commands as they are being written
set showcmd

" Make vim always show all text
set wrap

" Make vim search while typing
set incsearch

" Autoindent new lines
set autoindent

" Make vim exit visual mode without delay
set timeoutlen=1000 ttimeoutlen=0

" Abbreviations
iabbrev @@ simonwrydell@gmail.com
iabbrev ccopy Copyright 2017 Simon Rydell, all rights reserved

" CTRL-u in insert mode makes the current word uppercase
inoremap <c-u> <esc>mmviw~`ma

" Make jk escape in insert mode
" inoremap jk <esc>
" Temporarily disable esc to train above keybinding (no operation)
" inoremap <esc> <nop>

" Map away arrowkeys
nnoremap <Left> :echo "why?"<cr>
nnoremap <Right> :echo "why?"<cr>
nnoremap <Up> :echo "why?"<cr>
nnoremap <Down> :echo "why?"<cr>

" Open split window and edit .vimrc
nnoremap <leader>ev :split$MYVIMRC<cr>

" Source vimrc
nnoremap <leader>sv :source $MYVIMRC<cr>

" Put single quotes in
nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel

" Put quotes on your current selection in Visual mode
vnoremap <leader>' <esc>`<i'<esc>`>a'<esc>

" H moves to beginning of line and L to end of line
nnoremap H ^
nnoremap L $

" Change next/last bracket
onoremap inb :<c-u>normal! f(vi(<cr>
onoremap in( :<c-u>normal! f(vi(<cr>
onoremap ilb :<c-u>normal! F)vi(<cr>
onoremap il( :<c-u>normal! F)vi(<cr>

" Set local make options
" do not expand tabs to spaces
augroup filetype_make
	autocmd!
	autocmd FileType make set noexpandtab shiftwidth=4 softtabstop=0
augroup END

" Set local python options
" expand tabs to four spaces
augroup filetype_python
	autocmd!
	autocmd FileType python nnoremap <buffer> <localleader>c mm^i# <esc>``l
	autocmd FileType python set noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
	" autocmd FileType python set shiftwidth=4 softtabstop=4 expandtab
augroup END

" Setup folding for vimscript
augroup filetype_vim
	autocmd!
	autocmd FileType vim setlocal foldmethod=marker
augroup END
