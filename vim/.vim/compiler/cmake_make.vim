if exists("current_compiler")
	finish
endif

let current_compiler = "cmake_make"

" Usually use cmake to build out of source
" use the default 'errorformat'
CompilerSet errorformat&
CompilerSet makeprg=cmake\ \-H\.\ \-Bbuild\ \&\&\ make\ \-\-\no\-print\-directory\ \-C\ build
