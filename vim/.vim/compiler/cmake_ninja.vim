if exists('current_compiler')
  finish
endif
let current_compiler = 'cmake_make'

let s:cpo_save = &cpoptions
set cpoptions&vim

" Usually use cmake to build out of source
" use the default 'errorformat'
CompilerSet errorformat&
" This assumes that the binary is the same name as the file (without extension)
" and is located in build/bin/

" Build config from cmake to ninja
CompilerSet makeprg=cmake\ \-H\.\ \-Bbuild\ \-G\ Ninja\ \>\ /dev/null
" Build executable with ninja
CompilerSet makeprg+=\ \&\&\ ninja\ \-C\ build
" Run executable if found
CompilerSet makeprg+=\ \&\&\ test\ \-x\ \./build/bin/%:t:r\ \&\&\ \./build/bin/%:t:r

let &cpoptions = s:cpo_save
unlet s:cpo_save
