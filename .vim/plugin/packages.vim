command! PackUpdate packadd minpac | source ~/.vim/plugin/packages.vim | redraw | call minpac#update()
command! PackClean packadd minpac | source ~/.vim/plugin/packages.vim | call minpac#clean()

" If packages are not handled
if !isdirectory($HOME . '/.vim/pack')
	" Download minpac
	execute('silent !git clone https://github.com/k-takata/minpac.git ~/.vim/pack/minpac/opt/minpac')
	echom 'You may now install the plugins listed in ~/.vim/plugin/packages.vim by typing :PackUpdate'
endif

" This will only happen if packadd minpac has been executed
if !exists('*minpac#init')
	finish
endif

call minpac#init()

" Snippets
call minpac#add('SirVer/ultisnips')

" Autocompletion
" Note: Arch Linux specific: ncurses5-compat-libs
"		is needed from AUR for the completion menu
call minpac#add('Valloric/YouCompleteMe', {'do': '!./install.py --clang-completer --js-completer'})

" Send commands from one tmux pane to another
call minpac#add('benmills/vimux')

" Move through tmux/vim panes with the same keybindings
call minpac#add('christoomey/vim-tmux-navigator')

" Fuzzy finder.
" NOTE: The fzf binary is installed here in .vim/pack/minpac/start/fzf/bin
call minpac#add('junegunn/fzf', {'do': '!./install --bin'})

" Minpac updates itself
call minpac#add('k-takata/minpac', {'type': 'opt'})

" html, css, json and javascript formatter
call minpac#add('maksimr/vim-jsbeautify', {'type': 'opt'})

" Emmet, snippets for html, css
call minpac#add('mattn/emmet-vim', {'type': 'opt'})

" Add syntax highlighting for i3 config files
call minpac#add('mboughaba/i3config.vim', {'type': 'opt'})

" Colorscheme
call minpac#add('morhetz/gruvbox', {'type': 'opt'})

" Add syntax highlighting for javascript
call minpac#add('pangloss/vim-javascript', {'type': 'opt'})

" Operators which comment out text based on filetype
call minpac#add('tpope/vim-commentary')

" Git commands
call minpac#add('tpope/vim-fugitive')

" Helps with keeping a session saved that
" can be restored after a reboot
call minpac#add('tpope/vim-obsession')

" Interface for repeating plugin type commands with .
call minpac#add('tpope/vim-repeat')

" Functions for vimL scripting
call minpac#add('tpope/vim-scriptease', {'type': 'opt'})

" Operators used to surround text with character
call minpac#add('tpope/vim-surround')

" Asynchronous Lint Engine
call minpac#add('w0rp/ale')
