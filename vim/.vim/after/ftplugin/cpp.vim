if !exists('current_compiler')
  compiler cmake_make
endif

function! s:runClangFormat()
  let l:formatdiff = 1
  py3file ~/.vim/integrations/clang-format.py
endfunction

function! s:downloadClangFormatHelper()
  let url = 'https://llvm.org/svn/llvm-project/cfe/trunk/tools/clang-format/clang-format.py'
  let integrations_dir = expand('~/.vim/integrations/')

  execute '!wget --directory-prefix=' . integrations_dir . ' ' . url

  echom 'Downloaded clang-format helper script'
endfunction

if executable('clang-format')

  " Check if the helper is downloaded
  if !filereadable(expand('~/.vim/integrations/clang-format.py'))
    call s:downloadClangFormatHelper()
  endif

  let g:clang_format_fallback_style = 'LLVM'
  augroup clang_format_on_save
    autocmd!
    autocmd BufWritePre *.cpp,*.cc,*.h,*.hpp silent! call s:runClangFormat() | silent redraw!
  augroup END
endif
