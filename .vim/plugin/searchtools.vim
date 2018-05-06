let g:grepper = {}
" Search programs used.
let g:grepper.tools = ['grep', 'git', 'rg']

" Jump to the next result automatically
" Default: 1
let g:grepper.jump = 1

" Open the quickfix/location list on search
" Default: 1
let g:grepper.open = 1

let g:grepper.operator = {}
" Prompt search tool when using GrepperOperator
" Togle through with <Tab>
" Default: 0
let g:grepper.operator.prompt = 1

" Search for all occurences of TODO/FIXME in current git repository
command! Todo :Grepper -tool git -query '\(TODO\|FIXME\)'
