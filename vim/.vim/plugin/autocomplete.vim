if exists('g:loaded_srydell_autocomplete')
  finish
endif
let g:loaded_srydell_autocomplete = 1

" This file is used for autocompletion config.
" Mostly for CocVim 

" " Install extensions if not installed
" call coc#add_extension(
" 			\'coc-json',
" 			\'coc-python'
" 			\'coc-ultisnips',
" 			\'coc-vimlsp',
" 			\)

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

function! s:check_back_space() abort
  let l:col = col('.') - 1
  return !col || getline('.')[l:col - 1]  =~# '\s'
endfunction

" Use tab for trigger completion with characters ahead and navigate.
inoremap <silent><expr> <TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

" Use `[d` and `]d` to navigate diagnostics
nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call <SID>show_documentation()<CR>

" Remap for rename current word
nmap <leader>rn <Plug>(coc-rename)

" Remap for format selected region
xmap <silent> <leader>F <Plug>(coc-format-selected)
nmap <silent> <leader>F <Plug>(coc-format-selected)
