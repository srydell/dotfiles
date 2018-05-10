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

if has('folding')
	if has('windows')
		" BOX DRAWINGS HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
		" Draw the vertical border between vim splits as a continuous line
		set fillchars=vert:┃

		" MIDDLE DOT (U+00B7, UTF-8: C2 B7)
		" Draw the character used to fill out the fold
		set fillchars+=fold:·
	endif

	" Not as cool as syntax, but faster
	set foldmethod=indent

	" Start unfolded
	" set foldlevelstart=99
	set foldtext=folding#foldtext()
endif

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

" ---- Leader mappings ----
" <leader><lowerCaseLetter> for harmless commands
" <leader><upperCaseLetter> for potentially harmful commands

" Open split window and edit .vimrc
nnoremap <leader>ev :split$MYVIMRC<CR>

" Open split window and edit .tmux.conf
nnoremap <leader>et :split ~/.tmux.conf<CR>

" Open split window and edit filetype specific configs expand
nnoremap <silent> <leader>ef :call utils#EditFtplugin()<CR>

" Open a split and edit snippets for this filetype
nnoremap <leader>es :UltiSnipsEdit<CR>

" Fuzzy finder - fzf (buffers)
nnoremap <leader>fb :Buffers<CR>

" Fuzzy finder - fzf (commits)
nnoremap <leader>fc :Commits<CR>

" Fuzzy finder - fzf (files)
nnoremap <leader>ff :<C-u>FZF<CR>

" Fuzzy finder - fzf (snippets)
nnoremap <leader>fs :Snippets<CR>

" Find all the TODO/FIXME in current git project
" :Todo command specified in .vim/plugin/searchtools.vim
nnoremap <Leader>ft :Todo<CR>

" Search for the current word in the whole directory structure
nnoremap <Leader>* :Grepper -cword -noprompt<CR>

" Search for the current selection
nmap gs <Plug>(GrepperOperator)
xmap gs <Plug>(GrepperOperator)

" Run git commit -u
nnoremap <leader>gu :silent! Git add -u<CR>:redraw!<CR>

" Add file corresponding to current buffer
nnoremap <leader>ga :Gwrite<CR>

" Open commit message in a new buffer
" --verbose so that the changes are visible
"  while in the commit message
nnoremap <leader>gc :Gcommit --verbose<CR>

" Push the changes
nnoremap <leader>gp :Gpush<CR>

" Revert current file to last checked in version
" Same as running :!git checkout %
nnoremap <leader>Gr :Gread<CR>

" Open appropriate help on the word under the cursor
" Filetype dependent.
" Takes a browser and OS
nnoremap <silent> <leader>h :call utils#GetHelpDocs("qutebrowser", g:currentOS)<CR>

" Call Dispatch make with the appropriate handler (tmux, split, ...)
nnoremap <silent> <leader>m :Make<CR>

" Prompt for a command to run in the nearest tmux pane ( [t]mux [c]ommand )
nnoremap <silent> <leader>tc :VimuxPromptCommand<CR>

" Run last command executed by VimuxRunCommand ( [t]mux [r]un )
nnoremap <silent> <leader>tr :call tmux#vimuxRunLastCommandIfExists()<CR>

" Inspect runner pane ( [t]mux [i]nspect )
nnoremap <silent> <leader>ti :VimuxInspectRunner<CR>

" Zoom the tmux runner pane ( [t]mux [f]ullscreen )
nnoremap <silent> <leader>tf :VimuxZoomRunner<CR>

" Move through the buffer list
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [B :bfirst<CR>
nnoremap <silent> ]B :blast<CR>

" Move through the loclist
nnoremap <leader>l :call utils#ToggleList("Location List", 'l')<CR>
nnoremap <silent> [l :lprevious<CR>
nnoremap <silent> ]l :lnext<CR>
nnoremap <silent> [L :lfirst<CR>
nnoremap <silent> ]L :llast<CR>

" Move through the quickfix list
nnoremap <leader>q :call utils#ToggleList("Quickfix List", 'c')<CR>
nnoremap <silent> [q :cprevious<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [Q :cfirst<CR>
nnoremap <silent> ]Q :clast<CR>

" Yank to system clipboard
nnoremap <leader>y "*y
xnoremap <leader>y "*ygv<Esc>

" Paste from clipboard
nnoremap <silent><leader>p :set paste<CR>"*p<CR>:set nopaste<CR>
nnoremap <silent><leader>P :set paste<CR>"*P<CR>:set nopaste<CR>

" Source vimrc
nnoremap <leader>sv :source $MYVIMRC<CR>

" Fast substitutions for
" Word under the cursor in normal mode
" Visual selection in visual mode (Also copies selection into ")
" <leader>su for the current line.
" <leader>S for the whole file
nnoremap <leader>su :'{,'}s/\<<C-r><C-w>\>//g<left><left>
xnoremap <leader>su y:'{,'}s/<C-r><C-0>//g<left><left>
nnoremap <leader>S :%s/\<<C-r><C-w>\>//g<left><left>
xnoremap <leader>S y:%s/<C-r><C-0>//g<left><left>

" Write document
nnoremap <leader>w :write<CR>

" Write all buffers and exit
" If there are buffers without a name,
" or that are readonly, bring up a confirm prompt
nnoremap <leader>W :confirm wqall<CR>

" Unfold all folds under cursor
nnoremap <leader><Space> za
" Create fold for visually selected text
vnoremap <leader><Space> zf

" Normally zj/zk moves to folds even if they are open
nnoremap <silent> <leader>zj :call folding#NextClosedFold('j')<cr>
nnoremap <silent> <leader>zk :call folding#NextClosedFold('k')<cr>

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
