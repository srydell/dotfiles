if exists('g:autoloaded_srydell_cmake')
  finish
endif
let g:autoloaded_srydell_cmake = 1

" This function should be called from an autocmd
function! extra_filetypes#cmake#SetSpecialFiletype() abort
  if expand('%:t') ==# 'CMakeLists.txt'

    " Check upwards in the directories after a CMakeLists.txt file
    let directories = split(expand('%:p'), '/')[:-2]
    while !empty(directories)
      " Go up one level
      let directories = directories[:-2]
      if filereadable('/' . join(directories, '/') . '/CMakeLists.txt')
        " Found a CMakeLists.txt on a lower directory level
        " than the one opened
        setlocal filetype+=.sub_cmakelists
        return
      endif
    endwhile

    setlocal filetype+=.cmakelists
  else
    setlocal filetype+=.cmake_module
  endif
endfunction
