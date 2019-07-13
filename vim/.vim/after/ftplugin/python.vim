if !exists('current_compiler')
	compiler python
endif

function! s:canRunBlack()
	if exists('g:black_virtualenv')
		return executable(expand(g:black_virtualenv . '/bin/black'))
	endif
	return 0
endfunction

if s:canRunBlack()
	augroup black_format_on_save
		autocmd!
		autocmd BufWritePre *.py execute ':Black'
	augroup END
endif
