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

execute('CompilerSet makeprg=\~/\.vim/integrations/compiler/cmake_ninja\.sh\ %:t:r\ ' . g:number_of_threads)

let &cpoptions = s:cpo_save
unlet s:cpo_save
