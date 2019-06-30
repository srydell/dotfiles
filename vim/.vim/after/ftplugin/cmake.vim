if !exists("current_compiler")
  compiler cmake-format
endif

if executable('cmake-format')
	augroup cmake_format_on_save
		autocmd!
		autocmd BufWritePost *.cmake,CMakeLists.txt silent Make! | silent redraw!
	augroup END
endif
