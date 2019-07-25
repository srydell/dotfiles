augroup extra_filetypes
  autocmd!
  " Look for extra filetypes.
  " Ex: Filetype = cmake
  "     Calling a function in ~/.vim/autoload/extra_filetypes/cmake.vim 
  "     This might set the filetype as 'cmake.special_ft'
  autocmd Filetype text,cmake,cpp execute('call extra_filetypes#' . &filetype . '#set_special_filetype()')
augroup END
