" Enable filetype
filetype plugin indent on

" Enable syntax
syntax enable

" Set mapleader
let mapleader="\<Space>"
let maplocalleader="\<Space>"

" Colorscheme
function! CustomHighlights() abort
	" This overrides the current background in the colorscheme to NONE
	" Is used to get transparency in vim
	highlight Normal ctermbg=NONE
endfunction

augroup customColorscheme
	autocmd!
	autocmd ColorScheme * call CustomHighlights()
augroup END
" Encoding
set encoding=utf-8

set background=dark
let g:gruvbox_contrast_dark=1
silent! colorscheme gruvbox

" Always use filetype latex for .tex files
let g:tex_flavor = "latex"

" Make it easier to see tabs and newlines
set list
set listchars=tab:▸\ ,eol:¬

" Show absolute current row and relative rows from that
set number
set relativenumber

" Show commands as they are being written
set showcmd

" Softwrap text (without creating a newline)
set wrap

" Make vim highlight search while typing
set incsearch

" Autoindent new lines to match previous line
" Autoindent when creating new lines
set autoindent

" Make vim exit visual mode without delay
set timeoutlen=1000 ttimeoutlen=0

" Don't redraw buffer in all situations
set lazyredraw

" Ignore case if search is lowercase, otherwise case-sensitive
set ignorecase
set smartcase

" Allow the visual block to not be restricted by EOL
set virtualedit=block

" Disable error feedback via flashing screen
set visualbell t_vb=

" Default to splitting below and to the right with :split :vsplit
set splitbelow
set splitright

" If in an OS with a clipboard, let default (unnamed) register be clipboard
if has('clipboard')
	set clipboard^=unnamed
endif
" " Alternatively one could perhaps do
" " Yank to system clipboard
" nnoremap <leader>y "*y
" " Paste from clipboard
" nnoremap <leader>p :set paste<CR>"*p<CR>:set nopaste<CR>
" nnoremap <leader>P :set paste<CR>"*P<CR>:set nopaste<CR>
" " Yank to system clipboard from visual mode
" vnoremap <leader>y "*ygv

" Better autocomplete
set completeopt=longest,menuone,preview

" Completion with commands
set wildmenu
set wildmode=list:longest

" Ignore git direcories
set wildignore+=.git

" Ignore latex compilation files
set wildignore+=*.aux,*.out,*.toc

" Ignore pictures
set wildignore+=*.jpg,*.bmp,*.jpeg,*.gif,*.png

" Ignore vim swap files
set wildignore+=*.sw?

" Ignore Mac directory information
set wildignore+=*.DS_Store

" Ignore python byte code
set wildignore+=*.pyc

" Create directory structure for backup/swap/undo files
if !isdirectory($HOME . "/.vim/tmp")
	if exists("*mkdir")
		call mkdir($HOME . "/.vim/tmp/backup", "p")
		call mkdir($HOME . "/.vim/tmp/swap")
		call mkdir($HOME . "/.vim/tmp/undo")

		" Let vim store backup/swap/undo files in these directories
		" The double // will create files with whole path expanded.
		set backupdir=~/.vim/tmp/backup//
		set directory=~/.vim/tmp/swap//
		set undodir=~/.vim/tmp/undo//
		" Delete old backup, backup current file
		set backup
		set writebackup
	endif
endif

" ---- Insert mode ----
" CTRL-u in insert mode makes the current word uppercase
inoremap <c-u> <esc>mmviw~`ma

" ---- Normal mode ----
" Open qutebrowser with the word under the cursor as a 
" search term. Filetype dependent
nnoremap <leader>t :call OnlineDoc()<CR>

" Write document
nnoremap <leader><Space> :write<cr>

" Open split window and edit .vimrc
nnoremap <leader>ev :split$MYVIMRC<cr>

" Open split window and edit .tmux.conf
nnoremap <leader>et :split ~/.tmux.conf<cr>

" Open split window and edit filetype specific configs expand
" TODO: wrap in a function and make work
" nnoremap <leader>ef :split '~/.vim/ftplugin/' . expand("&filetype") . ".vim"

" Source vimrc
nnoremap <leader>sv :source $MYVIMRC<cr>

" ---- Visual mode ----
" Put quotes on your current selection in Visual mode
vnoremap <leader>' <esc>`<i'<esc>`>a'<esc>

" H moves to beginning of line and L to end of line
nnoremap H ^
nnoremap L $

" Make cursor still while joining lines. Using mark z
nnoremap J mzJ`z

" Center around search result
nnoremap n nzz

" Let vim treat virtual lines as real lines
" v:count works better with relativenumber
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'
nnoremap gj j
nnoremap gk k

" Make Y more consistent with C and D
nnoremap Y y$

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
	" OBS: Use ' instead of " to tell vim to use the string AS IS. Therefore
	" no substitutions to escaped characters are needed
	if &ft =~ "vim"
		execute(":help " . expand("<cword>"))
		return
	elseif &ft =~ "cpp"
		let s:urlTemplate = 'http://en.cppreference.com/mwiki/index.php?title=Special%3ASearch&search=SEARCHTERM&button='
	else
		let s:urlTemplate = 'https://duckduckgo.com/?q=SEARCHTERM'
	endif
	" TODO: Put browser as user specific
	" Requires s:browser to be in PATH
	let s:browser = "qutebrowser"

	let s:wordUnderCursor = expand("<cword>")

	" Replace SEARCHTERM by the selected word
	let s:url = substitute(s:urlTemplate, "SEARCHTERM", s:wordUnderCursor, "g")

	" Same as running ": silent! browser 'url'"
	let s:cmd = "silent !" . s:browser . " '" . s:url . "'"
	execute(s:cmd)
	" redraw necessary after silent since it wipes the buffer
	redraw!
endfunction
