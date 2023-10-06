if exists('current_compiler')
  finish
endif
let current_compiler = 'nasdaq_cpp'

let s:cpo_save = &cpoptions
set cpoptions&vim

" CompilerSet makeprg=/Users/simryd/code/dsf/docker_exec\.sh
CompilerSet makeprg=rsync\ \-r\ \-\-progress\ /Users/simryd/code/dsf/src\ bx0052:/newhome/bx0004/simryd/code/dsf

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

if exists('g:compiler_gcc_ignore_unmatched_lines')
  CompilerSet errorformat+=%-G%.%#
endif

let &cpoptions = s:cpo_save
unlet s:cpo_save
