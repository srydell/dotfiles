if exists('g:loaded_srydell_searchtools')
  finish
endif
let g:loaded_srydell_searchtools = 1

let g:grepper = {}
" Search programs used.
let g:grepper.tools = ['rg', 'grep', 'git']

" Jump to the next result automatically
" Default: 1
let g:grepper.jump = 1

" Open the quickfix/location list on search
" Default: 1
let g:grepper.open = 0

let g:grepper.operator = {}
" Prompt search tool when using GrepperOperator
" Togle through with <Tab>
" Default: 0
let g:grepper.operator.prompt = 1

" Search for all occurences of TODO/FIXME in current git repository
command! Todo :Grepper -tool git -query '\(TODO\|FIXME\)'
