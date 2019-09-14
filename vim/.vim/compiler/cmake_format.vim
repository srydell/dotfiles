if exists('current_compiler')
  finish
endif
let current_compiler = 'cmake_format'

let s:cpo_save = &cpoptions
set cpoptions&vim

" Use the default 'errorformat' (not important)
CompilerSet errorformat&
CompilerSet makeprg=cmake-format\ \-i\ %

let &cpoptions = s:cpo_save
unlet s:cpo_save
