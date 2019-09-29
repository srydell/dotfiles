if exists('g:loaded_srydell_compilers')
  finish
endif
let g:loaded_srydell_compilers = 1

" Step through b:valid_compilers
command! CompilerNext call compilers#StepThroughCompilers(1)
command! CompilerPrevious call compilers#StepThroughCompilers(-1)
