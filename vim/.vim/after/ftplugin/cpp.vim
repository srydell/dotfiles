" Default compilers. Use binding to toggle between them
if match(expand('%:p'), 'prototypes') != -1
  let g:valid_compilers = ['proto_clang++', 'proto_g++']
else
  let g:valid_compilers = ['cmake_ninja']
endif

if !exists('current_compiler')
  execute('compiler ' . g:valid_compilers[0])
endif

function! s:RunClangFormat()
  let l:formatdiff = 1
  py3file ~/.vim/integrations/clang-format.py
endfunction

if executable('clang-format')
  " Check if the helper is downloaded
  if !filereadable(expand('~/.vim/integrations/clang-format.py'))
    call integrations#installation#GetClangHelper()
  endif

  let g:clang_format_fallback_style = 'LLVM'
  augroup clang_format_on_save
    autocmd!
    autocmd BufWritePre *.cpp,*.cc,*.h,*.hpp silent! call s:RunClangFormat() | silent redraw!
  augroup END
endif
