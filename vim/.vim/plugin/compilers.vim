if exists('g:loaded_srydell_compilers')
  finish
endif
let g:loaded_srydell_compilers = 1

" Open quickfix on asyncrun finish (with height g:asyncrun_open)
let g:asyncrun_open = 8

" non-zero to save current(1) or all(2) modified buffer(s) before executing
let g:asyncrun_save = 2

" Step through b:valid_compilers
command! CompilerNext call compilers#StepThroughCompilers(1)
command! CompilerPrevious call compilers#StepThroughCompilers(-1)
