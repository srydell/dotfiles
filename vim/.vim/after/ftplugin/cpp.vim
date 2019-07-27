if !exists('current_compiler')
  compiler cmake_ninja
endif

function! s:runClangFormat()
  let l:formatdiff = 1
  py3file ~/.vim/integrations/clang-format.py
endfunction

if executable('clang-format')
  " Check if the helper is downloaded
  let clang_format_file = expand('~/.vim/integrations/clang-format.py')
  if !filereadable(clang_format_file)
    call integrations#installation#getClangHelper()
  endif

  let g:clang_format_fallback_style = 'LLVM'
  augroup clang_format_on_save
    autocmd!
    autocmd BufWritePre *.cpp,*.cc,*.h,*.hpp silent! call s:runClangFormat() | silent redraw!
  augroup END
endif
