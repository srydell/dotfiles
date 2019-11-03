if exists('current_compiler')
  finish
endif
let current_compiler = 'ctest'

let s:cpo_save = &cpoptions
set cpoptions&vim

if !exists('g:currentOS')
  let g:number_of_threads = 2
else
  if g:currentOS ==# 'Darwin'
    let g:number_of_threads = str2nr(system('sysctl -n hw.logicalcpu'))
  elseif g:currentOS ==# 'Linux'
    let g:number_of_threads = str2nr(system('nproc --all'))
  endif
endif

" Usually use cmake to build out of source
" use the default 'errorformat'
CompilerSet errorformat&

let s:options = [
      \ '--build_type\ ' . 'Release',
      \ '--cores\ ' . g:number_of_threads,
      \ '--extra_cmake_args\ -DENABLE_TESTING=ON',
      \ '--run_ctest\ on',
      \ ]

CompilerSet makeprg=\~/\.vim/integrations/compiler/run_ctest\.sh

" Set options
execute('CompilerSet makeprg+=\ ' . join(s:options, '\ '))

let &cpoptions = s:cpo_save
unlet s:cpo_save
