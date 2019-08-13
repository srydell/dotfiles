" Default compilers. Use binding to toggle between them
if expand('%:p:h:t') ==# 'prototypes'
  let g:valid_compilers = ['proto_clang++', 'proto_g++']
else
  let g:valid_compilers = ['cmake_ninja']
endif

if !exists('current_compiler')
  execute('compiler ' . g:valid_compilers[0])
endif

function! s:runClangFormat()
  let l:formatdiff = 1
  py3file ~/.vim/integrations/clang-format.py
endfunction

if executable('clang-format')
  " Check if the helper is downloaded
  if !filereadable(expand('~/.vim/integrations/clang-format.py'))
    call integrations#installation#getClangHelper()
  endif

  let g:clang_format_fallback_style = 'LLVM'
  augroup clang_format_on_save
    autocmd!
    autocmd BufWritePre *.cpp,*.cc,*.h,*.hpp silent! call s:runClangFormat() | silent redraw!
  augroup END
endif
