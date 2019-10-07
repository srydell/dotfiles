if exists('g:autoloaded_srydell_compiler')
  finish
endif
let g:autoloaded_srydell_compiler = 1

function! debug#compiler() abort
  source %
  " Empty quickfix list
  call setqflist([])
  " Search for a line starting with 'finish'
  " and put the rest into the quickfix list
  let start = search('^finish>') + 1
  let end = line('$')
  execute(start . ',' . end . ':cgetbuffer')
  " Open quickfix list
  copen
endfunction
