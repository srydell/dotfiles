" Where to save snippets
let g:UltiSnipsSnippetDirectories=["~/.vim/UltiSnips", "UltiSnips"]

" Triggers for Ultisnips
let g:UltiSnipsExpandTrigger="<C-j>"
let g:UltiSnipsJumpForwardTrigger="<C-j>"
let g:UltiSnipsJumpBackwardTrigger="<C-k>"

" Always split vertical when editing snippets files
let g:UltisnipsEditSplit="vertical"

" Assume that I'm always using Python 3
let g:UltisnipsUsePythonVersion=3

" Default fallback config if no config found in working directory
let g:ycm_global_ycm_extra_conf = "~/.ycm_extra_conf.py"

" Do not open a new buffer showing info about the completion
let g:ycm_add_preview_to_completeopt=0
set completeopt-=preview

" Look for Ultisnips snippets
let g:ycm_use_ultisnips_completer=1

" Use ctags tags files
let g:ycm_collect_identifiers_from_tags_files=1

" Let CompleteParameter.vim use UltiSnips keybindings
let g:complete_parameter_use_ultisnips_mapping = 1
