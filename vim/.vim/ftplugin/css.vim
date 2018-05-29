" Autocompletion
packadd emmet-vim 

" Parser
packadd vim-jsbeautify

" Only install emmet in this buffer
let g:user_emmet_install_global = 0

" Only enable emmet in insert mode
let g:user_emmet_mode='i'

" Emmet mappings start with user_emmet_leader_key
" Example: Expand command via <C-Y>,
let g:user_emmet_leader_key='<C-Y>'

" Format the current css file
" The configs are set by the file in g:editorconfig_Beautifier
nnoremap <buffer> <C-f> :call CSSBeautify()<CR>
vnoremap <buffer> <C-f> :call RangeCSSBeautify()<CR>

" Tabs are four columns
setlocal noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
