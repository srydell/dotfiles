if exists('current_compiler')
  finish
endif
let current_compiler = 'cmakelists'

let s:cpo_save = &cpoptions
set cpoptions&vim

" Call stack entries
CompilerSet errorformat=\ %#%f:%l\ %#\(%m\)
" CMake Error at test.cmake:5 (whatever)
"   This is an error because...
CompilerSet errorformat+=,%ECMake\ Error\ at\ %f:%l\ %m,
CompilerSet errorformat+=%Z\ \ %m

let s:options = [
      \ '--compiler\ ' . 'clang',
      \ '--generator\ ' . 'Ninja',
      \ '--build_type\ ' . 'Release',
      \ '-DENABLE_TESTING=ON\ -DENABLE_BENCHMARKS=ON',
      \ ]

CompilerSet makeprg=\~/\.vim/integrations/compiler/run_cmake\.sh

" Set options
execute('CompilerSet makeprg+=\ ' . join(s:options, '\ '))

let &cpoptions = s:cpo_save
unlet s:cpo_save

finish " Add example output after this line
