packadd vim-javascript
packadd emmet-vim 

" Only install emmet in this buffer
let g:user_emmet_install_global = 0

" Only enable emmet in insert mode
let g:user_emmet_mode='i'

" Emmet mappings start with user_emmet_leader_key
" Example: Expand command via <C-Y>,
let g:user_emmet_leader_key='<C-Y>'

" Tabs are four columns
setlocal noexpandtab shiftwidth=4 softtabstop=4 tabstop=4
