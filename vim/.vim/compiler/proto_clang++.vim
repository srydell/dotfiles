if exists('current_compiler')
  finish
endif
let current_compiler = 'proto_clang++'

let s:cpo_save = &cpoptions
set cpoptions&vim

let s:flags = [
      \ '-Wall',
      \ '-Werror',
      \ '-Wextra',
      \ '-Wshadow',
      \ '-Wnon-virtual-dtor',
      \ '-Wold-style-cast',
      \ '-Wcast-align',
      \ '-Wunused',
      \ '-Woverloaded-virtual',
      \ '-Wpedantic',
      \ '-Wconversion',
      \ '-Wsign-conversion',
      \ '-Wnull-dereference',
      \ '-Wdouble-promotion',
      \ '-Wdate-time',
      \ '-Wformat=2',
      \
      \ '-Wduplicate-enum',
      \ '-fdiagnostics-absolute-paths',
      \ ]

" Create bin
CompilerSet makeprg=mkdir\ \-p\ build/bin
" Compile file to bin
CompilerSet makeprg+=\ \&\&\ clang\+\+\ \-std\=c\+\+17\ \-O3\ \-o\ \./build/bin/%:t:r\ %:p
" Set flags
execute('CompilerSet makeprg+=\ ' . join(s:flags, '\ '))
" If there is an executable, run it
CompilerSet makeprg+=\ \&\&\ test\ \-x\ \./build/bin/%:t:r\ \&\&\ \./build/bin/%:t:r

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
