if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" Tabs are four columns
setlocal expandtab shiftwidth=4 softtabstop=4 tabstop=4

" This way the methods of classes are folded, but internal statements aren't
setlocal foldnestmax=2
