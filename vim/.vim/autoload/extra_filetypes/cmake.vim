" This function should be called from an autocmd
function! extra_filetypes#cmake#set_special_filetype() abort
  if expand('%:t') ==# 'CMakeLists.txt'
    setlocal filetype=cmake.cmakelists
  endif
endfunction
