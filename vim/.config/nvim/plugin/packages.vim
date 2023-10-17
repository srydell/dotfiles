command! PackUpdate packadd minpac | call minpac#init() | source ~/.vim/plugin/packages.vim | redraw | call minpac#update()
command! PackClean packadd minpac | call minpac#init() | source ~/.vim/plugin/packages.vim | call minpac#clean()

" If packages are not handled
if !isdirectory($HOME . '/.vim/pack')
  " Download minpac
  execute('silent !git clone https://github.com/k-takata/minpac.git ~/.vim/pack/minpac/opt/minpac')
  echomsg 'You may now install the plugins listed in ~/.vim/plugin/packages.vim by typing :PackUpdate'
endif

" This will only happen if packadd minpac has been executed
if !exists('*minpac#init')
  finish
endif

call minpac#init()

" Snippets
call minpac#add('srydell/ultisnips')
call minpac#add('srydell/vim-skeleton')

call minpac#add('srydell/vim-n-out')
" Autocompletion
" NOTE: Arch Linux specific: ncurses5-compat-libs
"       is needed from AUR for the completion menu
" call minpac#add('neoclide/coc.nvim', {'branch': 'release'})

" Send commands from one tmux pane to another
call minpac#add('benmills/vimux')

" Move through tmux/vim panes with the same keybindings
call minpac#add('christoomey/vim-tmux-navigator')

" Send code from one pane to another with motions
call minpac#add('jpalardy/vim-slime')

" Fuzzy finder.
" NOTE: The fzf binary is installed in .vim/pack/minpac/start/fzf/bin
call minpac#add('junegunn/fzf', {'do': '!./install --bin'})

" Minpac updates itself
call minpac#add('k-takata/minpac', {'type': 'opt'})

" Tags management
call minpac#add('ludovicchabant/vim-gutentags')

" Reads .editorconfig
call minpac#add('editorconfig/editorconfig-vim')

" Add ftdetect, compiler and other good stuff for elixir
call minpac#add('elixir-editors/vim-elixir')

" html, css, json and javascript formatter
call minpac#add('maksimr/vim-jsbeautify', {'type': 'opt'})

" Debugging
" call minpac#add('puremourning/vimspector')
call minpac#add('szw/vim-maximizer')

" A set of filetype based plugins
call minpac#add('sheerun/vim-polyglot')

" Python formatter
call minpac#add('python/black', {'type': 'opt'})

" Emmet, snippets for html, css
call minpac#add('mattn/emmet-vim', {'type': 'opt'})

" Add syntax highlighting for i3 config files
call minpac#add('mboughaba/i3config.vim', {'type': 'opt'})

" Asynchronous wrapper around different grep tools (Use multiple at once)
call minpac#add('mhinz/vim-grepper')

" Colorscheme
call minpac#add('gruvbox-community/gruvbox', {'type': 'opt'})

" Add syntax highlighting for javascript
call minpac#add('pangloss/vim-javascript', {'type': 'opt'})

" Operators which comment out text based on filetype
call minpac#add('tpope/vim-commentary')

" Asynchronously run tasks (can be used with :make)
call minpac#add('skywind3000/asyncrun.vim')

" Add end, fi, endfunction and so on automatically
call minpac#add('tpope/vim-endwise')

" Git commands
call minpac#add('tpope/vim-fugitive')

" Helps with keeping a session saved that
" can be restored after a reboot
call minpac#add('tpope/vim-obsession')

" Project configuration
" (used to find alternate files and some fancy Ultisnips tricks)
call minpac#add('tpope/vim-projectionist')

" Interface for repeating plugin type commands with .
call minpac#add('tpope/vim-repeat')

" Functions for vimL scripting
call minpac#add('tpope/vim-scriptease', {'type': 'opt'})

" Operators used to surround text with character
call minpac#add('tpope/vim-surround')

" Asynchronous Lint Engine
call minpac#add('w0rp/ale')
