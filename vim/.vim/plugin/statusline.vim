if exists('g:loaded_plugin_statusline')
  finish
endif
let g:loaded_plugin_statusline = 1

" Enable statusline
setlocal laststatus=2

" --- Statusline ---
" Path to file
setlocal statusline=%f

" Separator
setlocal statusline+=\ -\ 

" Label
" Filetype of the file
setlocal statusline+=%y

function! GetCompiler() abort
  return exists('b:current_compiler') ? ' {' . b:current_compiler . '} ' : ''
endfunction
" Current compiler
setlocal statusline+=%{GetCompiler()}

" Switch to the right side
setlocal statusline+=%=

" Current line
setlocal statusline+=%l
" Separator
setlocal statusline+=/
" Total lines
setlocal statusline+=%L
