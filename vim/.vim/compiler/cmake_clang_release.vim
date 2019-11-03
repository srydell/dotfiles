if exists('current_compiler')
  finish
endif
let current_compiler = 'cmake_clang_release'

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

" Default for clang
CompilerSet errorformat=
      \%*[^\"]\"%f\"%*\\D%l:%c:\ %m,
      \%*[^\"]\"%f\"%*\\D%l:\ %m,
      \\"%f\"%*\\D%l:%c:\ %m,
      \\"%f\"%*\\D%l:\ %m,
      \%-G%f:%l:\ %trror:\ (Each\ undeclared\ identifier\ is\ reported\ only\ once,
      \%-G%f:%l:\ %trror:\ for\ each\ function\ it\ appears\ in.),
      \%f:%l:%c:\ %trror:\ %m,
      \%f:%l:%c:\ %tarning:\ %m,
      \%f:%l:%c:\ %m,
      \%f:%l:\ %trror:\ %m,
      \%f:%l:\ %tarning:\ %m,
      \%f:%l:\ %m,
      \%f:\\(%*[^\\)]\\):\ %m,
      \\"%f\"\\,\ line\ %l%*\\D%c%*[^\ ]\ %m,
      \%D%*\\a[%*\\d]:\ Entering\ directory\ [`']%f',
      \%X%*\\a[%*\\d]:\ Leaving\ directory\ [`']%f',
      \%D%*\\a:\ Entering\ directory\ [`']%f',
      \%X%*\\a:\ Leaving\ directory\ [`']%f',
      \%DMaking\ %*\\a\ in\ %f

let s:options = [
      \ '--compiler\ ' . 'clang',
      \ '--generator\ ' . 'Ninja',
      \ '--build_type\ ' . 'Release',
      \ '--cores\ ' . g:number_of_threads,
      \ '--executable\ %:t:r',
      \ '--extra_cmake_args\ \"-DENABLE_TESTING=ON\ -DENABLE_BENCHMARKS=ON\"',
      \ ]

CompilerSet makeprg=\~/\.vim/integrations/compiler/build_and_run_cmake\.sh

" Set options
execute('CompilerSet makeprg+=\ ' . join(s:options, '\ '))

let &cpoptions = s:cpo_save
unlet s:cpo_save
