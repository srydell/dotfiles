" Parser
packadd vim-jsbeautify

" Format the current json file
" The configs are set by the file in g:editorconfig_Beautifier
nnoremap <buffer> <C-f> :call JsonBeautify()<CR>
vnoremap <buffer> <C-f> :call RangeJsonBeautify()<CR>
