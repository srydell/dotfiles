command! PackUpdate packadd minpac | source $MYVIMRC | redraw | call minpac#update()
command! PackClean packadd minpac | source $MYVIMRC | call minpac#clean()

if !exists('*minpac#init')
	finish
endif

call minpac#init()

call minpac#add('k-takata/minpac', {'type': 'opt'})

" General enhancements
call minpac#add('tpope/vim-surround')
call minpac#add('tpope/vim-commentary')
call minpac#add('tpope/vim-repeat')
call minpac#add('SirVer/ultisnips')

" Colorschemes
call minpac#add('morhetz/gruvbox', {'type': 'opt'})

" Autocompletion
" Arch Linux specific: ncurses5-compat-libs
" is needed from AUR for the completion menu
call minpac#add('Valloric/YouCompleteMe', {'do': '!./install.py --clang-completer'})

" Offline documentation browser
call minpac#add('KabbAmine/zeavim.vim')
