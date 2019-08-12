function! compilers#StepThroughCompilers(step) abort
  if type(a:step) != type(0)
    echoerr 'Input must be a number. Got: ' . a:step
    return
  endif

  if !exists('g:valid_compilers') || !exists('b:current_compiler') || len(g:valid_compilers) == 0
    return
  endif

  let comp_index = index(g:valid_compilers, b:current_compiler)
  let next_compiler = comp_index == -1 ?
        \ g:valid_compilers[0] :
        \ g:valid_compilers[(comp_index + a:step) % len(g:valid_compilers)]

  execute('compiler ' . next_compiler)
endfunction
