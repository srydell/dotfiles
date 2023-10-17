if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" Folding
setlocal foldmethod=marker

" Tabs are four columns
setlocal noexpandtab shiftwidth=4 softtabstop=4 tabstop=4

setlocal commentstring=\"\ %s
