if exists("current_compiler")
  finish
endif
let current_compiler = "cmake-format"

let s:cpo_save = &cpo
set cpo&vim

" Use the default 'errorformat' (not important)
CompilerSet errorformat&
CompilerSet makeprg=cmake-format\ \-i\ %

let &cpo = s:cpo_save
unlet s:cpo_save
