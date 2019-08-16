if exists('g:autoloaded_srydell_compilers')
  finish
endif
let g:autoloaded_srydell_compilers = 1

function! compilers#StepThroughCompilers(step) abort
  if type(a:step) != type(0)
    echohl WarningMsg
    echomsg 'Input must be a number. Got: ' . a:step
    echohl None
    return
  endif

  if !exists('g:valid_compilers') || !exists('b:current_compiler') || len(g:valid_compilers) == 0
    return
  endif

  let l:comp_index = index(g:valid_compilers, b:current_compiler)
  let l:next_compiler = l:comp_index == -1 ?
        \ g:valid_compilers[0] :
        \ g:valid_compilers[(l:comp_index + a:step) % len(g:valid_compilers)]

  execute('compiler ' . l:next_compiler)
endfunction
