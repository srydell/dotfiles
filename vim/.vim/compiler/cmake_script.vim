if exists('current_compiler')
  finish
endif
let current_compiler = 'cmake_script'

let s:cpo_save = &cpoptions
set cpoptions&vim

" Call stack entries
CompilerSet errorformat=\ %#%f:%l\ %#\(%m\)

" NOTE: Multiple %m only expands the error message
" For errors such as:
" CMake Error at test.cmake:5 (whatever)
"   This is an error because...
CompilerSet errorformat+=,%ECMake\ Error\ at\ %f:%l\ %m,
CompilerSet errorformat+=%Z\ \ %m

CompilerSet makeprg=cmake\ \-P\ %:p

let &cpoptions = s:cpo_save
unlet s:cpo_save
