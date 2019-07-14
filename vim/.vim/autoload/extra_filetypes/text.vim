" This function should be called from an autocmd
function! extra_filetypes#text#set_special_filetype() abort
  if expand('%:t') ==# 'conanfile.txt'
    setlocal filetype=conanfile_txt.text
  endif
endfunction
