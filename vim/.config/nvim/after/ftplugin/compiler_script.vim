if exists('g:did_ftplugin')
  finish
endif
let g:did_ftplugin = 1

" Override the Make command (just easier to remember)
nnoremap m<CR> :call debug#compiler()<CR>
