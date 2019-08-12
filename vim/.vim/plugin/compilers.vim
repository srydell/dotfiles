if exists('g:loaded_plugin_compilers')
  finish
endif
let g:loaded_plugin_compilers = 1

" Step through g:valid_compilers
command! CompilerNext call compilers#StepThroughCompilers(1)
command! CompilerPrevious call compilers#StepThroughCompilers(-1)
