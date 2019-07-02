if !exists("current_compiler")
  compiler cmake_make
endif

function! s:Formatonsave()
  let l:formatdiff = 1
  py3file ~/.vim/integrations/clang-format.py
endfunction

if executable('clang-format')
	let g:clang_format_fallback_style = 'LLVM'
	augroup clang_format_on_save
		autocmd!
		autocmd BufWritePre *.cpp,*.cc,*.h,*.hpp silent! call s:Formatonsave() | silent redraw!
	augroup END
endif
