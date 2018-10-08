" Where Ultisnips searches for snippet files
let g:UltiSnipsSnippetDirectories = ["~/.vim/snips", "snips"]

" Expand and cycle settings for snippets
let g:UltiSnipsExpandTrigger = "<C-j>"
let g:UltiSnipsJumpForwardTrigger = "<C-j>"
let g:UltiSnipsJumpBackwardTrigger = "<C-k>"
" inoremap <C-j> <C-r>=CompleteSnippet()<CR>

" Where to open split on :UltiSnipsEdit
let g:UltisnipsEditSplit = "vertical"

" Always use Python 3
let g:UltisnipsUsePythonVersion = 3

let g:LanguageClient_serverCommands = {
    \ 'python': ['/usr/local/bin/pyls'],
    \ 'cpp': ['ccls', '--log-file=/tmp/cc.log'],
    \ 'c': ['ccls', '--log-file=/tmp/cc.log'],
    \ }

nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
nnoremap <silent> <F2> :call LanguageClient#textDocument_rename()<CR>
" let g:deoplete#enable_at_startup = 1

" Important: :help Ncm2PopupOpen for more information
set completeopt=noinsert,menuone,noselect

" Always draw the signcolumn.
set signcolumn=yes

" suppress the annoying 'match x of y', 'The only match' and 'Pattern not
" found' messages
set shortmess+=c

" augroup ncm2_and_completesnip
" 	" enable ncm2 for all buffers
" 	autocmd BufEnter * call ncm2#enable_for_buffer()
" 	" autocmd CompleteDone * call CompleteSnippet()
" augroup END

" Use deoplete.
let g:deoplete#enable_at_startup = 1

inoremap <expr><S-TAB>  pumvisible() ? "\<C-p>" : "\<S-TAB>"
inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

let g:ulti_expand_res = 0 "default value, just set once
function! CompleteSnippet()
  if empty(v:completed_item)
    return
  endif

  call UltiSnips#ExpandSnippetOrJump()
  if g:ulti_expand_res > 0
    return
  endif
  
  let l:complete = type(v:completed_item) == v:t_dict ? v:completed_item.word : v:completed_item
  let l:comp_len = len(l:complete)

  let l:cur_col = mode() == 'i' ? col('.') - 2 : col('.') - 1
  let l:cur_line = getline('.')

  let l:start = l:comp_len <= l:cur_col ? l:cur_line[:l:cur_col - l:comp_len] : ''
  let l:end = l:cur_col < len(l:cur_line) ? l:cur_line[l:cur_col + 1 :] : ''

  call setline('.', l:start . l:end)
  call cursor('.', l:cur_col - l:comp_len + 2)

  call UltiSnips#Anon(l:complete)
endfunction

" let g:ycm_python_binary_path = 'python3'

" " Don't open a buffer containing information about the completion
" let g:ycm_add_preview_to_completeopt = 0

" let g:ycm_global_ycm_extra_conf='~/.vim/.ycm_extra_conf.py'

" " Use ctags files for autocompletion
" let g:ycm_collect_identifiers_from_tags_files = 1

" " Turn on completion in comments
" let g:ycm_complete_in_comments=1

" " Cycle setting for completion
" let g:ycm_key_list_select_completion = ['<TAB>', '<Down>']
" let g:ycm_key_list_previous_completion = ['<S-TAB>', '<Up>']
