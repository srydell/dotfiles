if exists("current_compiler")
	finish
endif
let current_compiler = "cmake_make"

let s:cpo_save = &cpo
set cpo&vim

" Usually use cmake to build out of source
" use the default 'errorformat'
CompilerSet errorformat&
CompilerSet makeprg=cmake\ \-H\.\ \-Bbuild\ \&\&\ make\ \-\-\no\-print\-directory\ \-C\ build

let &cpo = s:cpo_save
unlet s:cpo_save