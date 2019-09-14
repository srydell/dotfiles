if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" Tabs are four columns
setlocal noexpandtab shiftwidth=4 softtabstop=4 tabstop=4

" Comment with //
setlocal commentstring=//\ %s

" Enable only cppcheck for C++.
let b:ale_linters = ['cppcheck']
