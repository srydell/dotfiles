if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" Tabs are two columns
setlocal expandtab shiftwidth=2 softtabstop=2 tabstop=2

" Comment with //
setlocal commentstring=//\ %s
