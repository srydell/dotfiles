augroup extra_filetypes
	autocmd!
	" Look for extra filetypes.
	" Ex: Filetype = cmake
	"     Calling a function in ~/.vim/autoload/extra_filetypes/cmake.vim 
	"     This might set the filetype as 'special_ft.cmake'
	autocmd Filetype text,cmake execute('call extra_filetypes#' . &filetype . '#set_special_filetype()')
augroup END
