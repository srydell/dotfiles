if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" Parser
packadd vim-jsbeautify

" Tabs are four columns
setlocal expandtab shiftwidth=4 softtabstop=4 tabstop=4

" Format the current json file
" The configs are set by the file in g:editorconfig_Beautifier
nnoremap <buffer> <C-f> :call JsonBeautify()<CR>
vnoremap <buffer> <C-f> :call RangeJsonBeautify()<CR>
