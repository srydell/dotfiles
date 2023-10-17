if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

let g:markdown_fenced_languages = ['html', 'python', 'bash=sh']

setlocal spell

" Maximum number of syntax highlighted code block lines
" Default: 50
" let g:markdown_minlines = 50
