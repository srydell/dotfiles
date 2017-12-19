" Package manager
source ~/.vim/packages.vim

" Autocompletion settings
source ~/.vim/autocomplete.vim

" Statusline settings
source ~/.vim/statusline.vim

" Enable filetype
filetype on
filetype plugin indent on

" Enable syntax
syntax enable

" Set mapleader
let mapleader="\<Space>"
let maplocalleader="\<Space>"

" Colorscheme
set background=dark
let g:gruvbox_contrast_dark=1
silent! colorscheme gruvbox

" Make it easier to see tabs and newlines
set list
set listchars=tab:▸\ ,eol:¬

" Show absolute current row and relative rows from that
set number
set relativenumber

" No swap files
set noswapfile

" Show commands as they are being written
set showcmd

" Softwrap text (without creating a newline)
set wrap

" Make vim highlight search while typing
set incsearch

" Autoindent new lines to match previous line
" Smart autoindent when creating new lines
set autoindent
set smartindent

" Make vim exit visual mode without delay
set timeoutlen=1000 ttimeoutlen=0

" Don't redraw buffer in all situations
set lazyredraw

" Ignore case if search is lowercase, otherwise case-sensitive
set ignorecase
set smartcase

" Allow the visual block to not be restricted by EOL
set virtualedit=block

" If in an OS with a clipboard, let default (unnamed) register be clipboard
if has('clipboard')
	set clipboard=unnamed
endif

" Let vim store backup/swap/undo files in these directories
" Have the benefit of being able to recover from crashes without being
" bothered with swap files
" The double // will create files with whole path expanded. This will
" hopefully result in no name collisions
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set undodir=~/.vim/undo//

" ---- Insert mode ----
" Abbreviations
iabbrev @@ simonwrydell@gmail.com
iabbrev ccopy Copyright 2017 Simon Rydell, all rights reserved

" CTRL-u in insert mode makes the current word uppercase
inoremap <c-u> <esc>mmviw~`ma

" ---- Normal mode ----
" Map away arrowkeys
nnoremap <Left> :echo "why?"<cr>
nnoremap <Right> :echo "why?"<cr>
nnoremap <Up> :echo "why?"<cr>
nnoremap <Down> :echo "why?"<cr>

" Open qutebrowser with the word under the cursor as a 
" search term. Filetype dependent
noremap <leader>t :call OnlineDoc()<CR>

" Open split window and edit .vimrc
nnoremap <leader><Space> :write<cr>

" Open split window and edit .vimrc
nnoremap <leader>ev :split$MYVIMRC<cr>

" Source vimrc
nnoremap <leader>sv :source $MYVIMRC<cr>

" Put single quotes in
nnoremap <leader>' viw<esc>a'<esc>bi'<esc>lel

" H moves to beginning of line and L to end of line
nnoremap H ^
nnoremap L $

" ---- Visual mode ----
" Put quotes on your current selection in Visual mode
vnoremap <leader>' <esc>`<i'<esc>`>a'<esc>

" ---- Custom objects ----
" Change next/last bracket
onoremap inb :<c-u>normal! f(vi(<cr>
onoremap in( :<c-u>normal! f(vi(<cr>
onoremap ilb :<c-u>normal! F)vi(<cr>
onoremap il( :<c-u>normal! F)vi(<cr>

" Function to open a search for the word under the cursor.
" Depending on which filetype is in the current buffer, different
" search engines will be used
function! OnlineDoc()
	" Depending on which filetype, use different search engines
	if &ft =~ "vim"
		let s:urlTemplate = "https://duckduckgo.com/?q=SEARCHTERM"
	elseif &ft =~ "cpp"
		let s:urlTemplate = "http://en.cppreference.com/mwiki/index.php?title=Special%3ASearch&search=SEARCHTERM&button="
	else
		return
	endif
	" TODO: Put browser as user specific
	" Requires s:browser to be in PATH
	let s:browser = "qutebrowser"

	let s:wordUnderCursor = expand("<cword>")

	" Escape % character. % is the current filename
	let s:url = substitute(s:urlTemplate, "%", "\\%", "g")

	" Replace SEARCHTERM by the selected word
	let s:url = substitute(s:urlTemplate, "SEARCHTERM", s:wordUnderCursor, "g")

	" Same as running ": silent! browser 'url'"
	let s:cmd = "silent !" . s:browser . " '" . s:url . "'"
	execute(s:cmd)
	" redraw necessary after silent since it wipes the buffer
	redraw!
endfunction

" Set local make options
" do not expand tabs to spaces
augroup filetype_make
	autocmd!
	autocmd FileType make set noexpandtab shiftwidth=4 softtabstop=0
augroup END

" Set local cpp options
" expand tabs to four columns
augroup filetype_python
	autocmd!
	autocmd FileType cpp set noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
augroup END

" Set local python options
" expand tabs to four columns
augroup filetype_python
	autocmd!
	autocmd FileType python set noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
augroup END

" Latex autocompilation
augroup filetype_latex
	autocmd!
	" Compile latex with rubber upon saving the file
	" TODO: put in sighup to update mupdf automatically using
	"	$ pkill -HUP mupdf
	"	Must check whether there is an open mupdf running though, maybe even
	"	connected to the current buffer would be good
	autocmd FileType tex nnoremap <leader>c :w<CR>:silent !rubber --pdf --warn all %<CR>:redraw!<CR>
	" View PDF. '%:r' is current file's root (base) name
	autocmd FileType tex nnoremap <leader>v :silent !mupdf %:r.pdf &<CR><CR>
augroup END

" Setup folding for vimscript
augroup filetype_vim
	autocmd!
	autocmd FileType vim setlocal foldmethod=marker
	autocmd FileType vim set noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
augroup END

" Adding commentstyle # for filetype taskrc
autocmd FileType taskrc setlocal commentstring=#\ %s
