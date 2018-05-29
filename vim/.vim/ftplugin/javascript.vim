" Syntax highlighting
packadd vim-javascript

" Parser
packadd vim-jsbeautify

" Format the current javascript file
" The configs are set by the file in g:editorconfig_Beautifier
nnoremap <buffer> <C-f> :call JsBeautify()<CR>
vnoremap <buffer> <C-f> :call RangeJsBeautify()<CR>

" Tabs are four columns
setlocal noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
