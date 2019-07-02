if !exists("current_compiler")
  compiler cmake_make
endif

function! s:Formatonsave()
  let l:formatdiff = 1
  py3f ~/.vim/integrations/clang-format.py
endfunction

if executable('clang-format')
	augroup clang_format_on_save
		autocmd!
		autocmd BufWritePre *.cpp,*.cc,*.h,*.hpp silent! call s:Formatonsave() | silent redraw!
	augroup END
endif
