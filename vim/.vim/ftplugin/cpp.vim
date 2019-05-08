" Tabs are four columns
setlocal noexpandtab shiftwidth=4 softtabstop=4 tabstop=4

" Comment with //
setlocal commentstring=//\ %s

" Enable only cppcheck for C++.
let b:ale_linters = ['cppcheck']

" Usually use cmake to build out of source
set makeprg=cmake\ \-H\.\ \-Bbuild\ \&\&\ make\ \-\-\no\-print\-directory\ \-C\ build
