if exists('g:loaded_srydell_snippets')
  finish
endif
let g:loaded_srydell_snippets = 1

" Where Ultisnips searches for snippet files
let g:UltiSnipsSnippetDirectories = ['~/.vim/snips', 'snips']

" Expand and cycle settings for snippets
let g:UltiSnipsExpandTrigger = '<C-j>'
let g:UltiSnipsJumpForwardTrigger = '<C-j>'
let g:UltiSnipsJumpBackwardTrigger = '<C-k>'

" Where to open split on :UltiSnipsEdit
let g:UltisnipsEditSplit = 'vertical'

" Always use Python 3
let g:UltisnipsUsePythonVersion = 3
