" Where Ultisnips searches for snippet files
let g:UltiSnipsSnippetDirectories=["~/.vim/snips", "snips"]

" Expand and cycle settings for snippets
let g:UltiSnipsExpandTrigger="<C-n>"
let g:UltiSnipsJumpForwardTrigger="<C-n>"
let g:UltiSnipsJumpBackwardTrigger="<C-p>"

" Where to open split on :UltiSnipsEdit
let g:UltisnipsEditSplit="vertical"

" Always use Python 3
let g:UltisnipsUsePythonVersion=3
let g:ycm_python_binary_path = 'python3'

" Don't open a buffer containing information about the completion
let g:ycm_add_preview_to_completeopt=0
set completeopt-=preview

let g:ycm_global_ycm_extra_conf = "~/.ycm_extra_conf.py"

" Use ctags files for autocompletion
let g:ycm_collect_identifiers_from_tags_files=1

" Cycle setting for completion
let g:ycm_key_list_select_completion = ['<TAB>', '<Down>']
let g:ycm_key_list_previous_completion = ['<S-TAB>', '<Up>']

" Let CompleteParameter.vim use UltiSnips keybindings
let g:complete_parameter_use_ultisnips_mapping = 1
