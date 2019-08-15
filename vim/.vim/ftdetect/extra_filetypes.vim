" Look for extra filetypes.
" Ex: Filetype = cmake
"     Calling a function in ~/.vim/autoload/extra_filetypes/cmake.vim 
"     This might set the filetype as 'cmake.special_ft'
autocmd BufRead *.cmake,CMakeLists.txt,*.cpp,*.cc,*.cxx,*.h,*.hpp execute('call extra_filetypes#' . &filetype . '#SetSpecialFiletype()')
