if !exists('current_compiler')
  compiler cmake_ninja
endif

" Default compilers. Use binding to toggle between them
let g:valid_compilers = ['cmake_ninja', 'gcc']

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
