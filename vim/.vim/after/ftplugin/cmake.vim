if !exists("current_compiler")
  compiler cmake_format
endif

if executable('cmake-format')
	augroup cmake_format_on_save
		autocmd!
		autocmd BufWritePre *.cmake,CMakeLists.txt silent! Make! | silent redraw!
	augroup END
endif
