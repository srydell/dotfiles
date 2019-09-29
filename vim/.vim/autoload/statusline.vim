if exists('g:autoloaded_srydell_statusline')
  finish
endif
let g:autoloaded_srydell_statusline = 1

function! statusline#init()
  augroup statusline
    autocmd!
    autocmd VimEnter,WinEnter,BufWinEnter   * call statusline#refresh()
    autocmd FileType,VimResized             * call statusline#refresh()
    autocmd BufHidden,BufWinLeave,BufUnload * call statusline#refresh()
  augroup END

endfunction

function! statusline#refresh()
  for nr in range(1, winnr('$'))
    if !s:ignored(nr)
      call setwinvar(nr, '&statusline', '%!statusline#main(' . nr . ')')
    endif
  endfor
endfunction

function! statusline#main(winnr)
  let l:winnr = winbufnr(a:winnr) == -1 ? 1 : a:winnr
  let l:active = l:winnr == winnr()
  let l:bufnr = winbufnr(l:winnr)
  let l:buftype = getbufvar(l:bufnr, '&buftype')
  let l:filetype = getbufvar(l:bufnr, '&filetype')

  " Try to call buffer type specific functions
  if len(l:buftype) != 0
    try
      return s:{l:buftype}(l:bufnr, l:active, l:winnr)
    catch
    endtry
  endif

  " Try to call filetype specific functions
  if len(l:filetype) != 0
    try
      return s:{l:filetype}(l:bufnr, l:active, l:winnr)
    catch
    endtry
  endif

  return s:main(l:bufnr, l:active)
endfunction

"
" Main statusline function
"
function! s:main(bufnr, active)
  " Path to file
  let l:stat = '%f'

  " Separator
  let l:stat .= ' '

  " Filetype
  let l:stat .= '%y'

  " Current compiler
  let l:stat .= exists('b:current_compiler') ? ' {' . b:current_compiler . '} ' : ''

  " Switch to the right side
  let l:stat .= '%='

  " Current line
  let l:stat .= '%l'
  " Separator
  let l:stat .= '/'
  " Total lines
  let l:stat .= '%L'
  return l:stat
endfunction

"
" Buffer type functions
"
function! s:help(bufnr, active, winnr)
  let l:name = bufname(a:bufnr)
  return s:color(' ' . fnamemodify(l:name, ':t:r') . ' %= HELP ',
        \ 'SLHighlight', a:active)
endfunction

function! s:manpage(bufnr, active, winnr)
  return s:color(' %<%f', 'SLHighlight', a:active)
endfunction

"
" Tabline
"
function! statusline#init_tabline()
  set tabline=%!statusline#get_tabline()
  highlight TabLine
        \ cterm=none ctermbg=12 ctermfg=8
        \ gui=none guibg=#657b83 guifg=#eee8d5 guisp=#657b83
  highlight TabLineSel
        \ cterm=none ctermbg=12 ctermfg=15
        \ gui=none guibg=#657b83 guifg=#ffe055 guisp=#657b83
  highlight TabLineFill
        \ cterm=none ctermbg=12 ctermfg=8
        \ gui=none guibg=#657b83 guifg=#eee8d5 guisp=#657b83
endfunction

function! statusline#get_tabline()
  let s = ' '
  for i in range(1, tabpagenr('$'))
    let s .= s:color('%{statusline#get_tablabel(' . i . ')} ',
          \ 'TabLineSel', i == tabpagenr())
  endfor

  return s
endfunction

function! statusline#get_tablabel(n)
  let buflist = tabpagebuflist(a:n)
  let winnr = tabpagewinnr(a:n)

  let name = bufname(buflist[winnr - 1])
  if name !=# ''
    let label = fnamemodify(name, ':t')
  else
    let type = getbufvar(buflist[winnr - 1], '&buftype')
    if type !=# ''
      let label = '[' . type . ']'
    else
      let label = '[No Name]'
    endif
  endif

  return printf('%1s %-15s', a:n, label)
endfunction

"
" Utilities
"
function! s:color(content, group, active)
  if a:active
    return '%#' . a:group . '#' . a:content . '%*'
  else
    return a:content
  endif
endfunction

function! s:ignored(winnr)
  let l:name = bufname(winbufnr(a:winnr))

  if l:name =~# '^\%(undotree\|diffpanel\)'
    return 1
  endif

  return 0
endfunction
