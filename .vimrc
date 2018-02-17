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

" Check current operating system
" Linux for Linux
" Darwin for MacOS
if !exists("g:currentOS")
	let g:currentOS = substitute(system('uname'), '\n', '', '')
endif

set background=dark
let g:gruvbox_contrast_dark=1
silent! colorscheme gruvbox

" Make it easier to see tabs and newlines
set list
set listchars=tab:▸\ ,eol:¬

" Show absolute current row and relative rows from that
set number
set relativenumber

" Make backspace be able to delete indent and before starting position
set backspace=indent,eol,start

" Show commands as they are being written
set showcmd

" Do not show the current mode (insert, visual, ...)
set noshowmode

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

" Be able to hide unsaved buffers while editing new ones
set hidden

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
set completeopt=longest,menuone

" Completion with commands
set wildmenu
set wildmode=longest,full

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

" Let vim store backup/swap/undo files in these directories
" The double // will create files with whole path expanded.
set backupdir=~/.vim/tmp/backup//
set directory=~/.vim/tmp/swap//
set undodir=~/.vim/tmp/undo//
" Delete old backup, backup current file
set backup
set writebackup

" Persistent undo tree after exiting vim
set undofile

" How many levels are saved in each file
set undolevels=100

" Always use filetype latex for .tex files
let g:tex_flavor = "latex"

" Always use filetype latex for .tex files
let g:editorconfig_Beautifier = "~/.vim/.jsBeautifierConfig"

" ---- Normal mode ----
" Open appropriate help on the word under the cursor
" Filetype dependent
" Takes a browser and OS
nnoremap <leader>h :call functions#GetHelpDocs("qutebrowser", g:currentOS)<CR>

" Write document
nnoremap <leader>w :write<CR>

" Write all buffers and exit
" If there are buffers without a name,
" or that are readonly, bring up a confirm prompt
nnoremap <leader>W :confirm wqall<CR>

" Open split window and edit .vimrc
nnoremap <leader>ev :split$MYVIMRC<CR>

" Open split window and edit .tmux.conf
nnoremap <leader>et :split ~/.tmux.conf<CR>

" Open split window and edit filetype specific configs expand
nnoremap <leader>ef :call functions#EditFtplugin()<CR>

" Open a split and edit snippets for this filetype
nnoremap <leader>es :UltiSnipsEdit<CR>

" Source vimrc
nnoremap <leader>sv :source $MYVIMRC<CR>

" Generate a tags file
nnoremap <leader>C :!ctags -R<CR>

" -- Tpope fugitive commands --
" Starting with <leader>g for harmless commands
" Starting with <leader>G for potentially harmful commands

" Run git commit -u
nnoremap <leader>gu :silent! Git add -u<CR>:redraw!<CR>

" Add file corresponding to current buffer
nnoremap <leader>ga :Gwrite<CR>

" Open commit message in a new buffer
" --verbose so that the changes are visible
"  while in the commit message
nnoremap <leader>gc :Gcommit --verbose<CR>

" Push the changes
nnoremap <leader>Gp :Gpush<CR>

" Revert current file to last checked in version
" Same as running git checkout %
nnoremap <leader>Gr :Gread<CR>

" Populate the quickfix list with errors generated from make
" The ! sign makes vim not automatically jump to the first quickfix
" Works automatically with makefiles but may want to be setting
" setlocal makeprg=COMPILER\ %
" setlocal errorformat=...
" To populate the quickfix list for other compilers
nnoremap <leader>m :make!<CR>

" Move through the quiqkfix list
nnoremap <silent> [q :cprevious<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [q :cfirst<CR>
nnoremap <silent> ]q :clast<CR>

" Move through the buffer list
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [B :bfirst<CR>
nnoremap <silent> ]B :blast<CR>

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

" Enable builtin matchit feature.
" Hit '%' on 'if' to jump to 'else'.
runtime macros/matchit.vim
