if exists('current_compiler')
  finish
endif
let current_compiler = 'cmake_ninja'

let s:cpo_save = &cpoptions
set cpoptions&vim

if !exists('g:currentOS')
  let g:number_of_threads = 2
else
  if g:currentOS ==# 'Darwin'
    let g:number_of_threads = system('sysctl -n hw.logicalcpu')
  elseif g:currentOS ==# 'Linux'
    let g:number_of_threads = system('nproc --all')
  endif
endif

" Usually use cmake to build out of source
" use the default 'errorformat'
CompilerSet errorformat&

" NOTE: This assumes that the binary is the same name as the file (without extension)
"       and is located in build/bin/

" Build config from cmake to ninja
CompilerSet makeprg=cmake\ \-S\.\ \-Bbuild\ \-G\ Ninja
" cmake options: Debug and using clang++
CompilerSet makeprg+=\ \-D\ CMAKE_BUILD_TYPE\=Debug\ \-D\ CMAKE_CXX_COMPILER\=\$\(command\ \-v\ clang\+\+\)
CompilerSet makeprg+=\ \>\ /dev/null
" Build executable
execute('CompilerSet makeprg+=\ \&\&\ cmake\ \-\-build\ build\ \-j' . g:number_of_threads)
" Run executable if found
CompilerSet makeprg+=\ \&\&\ test\ \-x\ \./build/bin/%:t:r\ \&\&\ \./build/bin/%:t:r

let &cpoptions = s:cpo_save
unlet s:cpo_save
