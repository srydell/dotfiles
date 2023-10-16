if exists('g:autoloaded_srydell_utils')
  finish
endif
let g:autoloaded_srydell_utils = 1

function! s:GetBufferList() abort
  redir =>buflist
  silent! buffers!
  redir END
  return buflist
endfunction

function! utils#ToggleList(bufname, prefix) abort
  " :bufname: String - 'Location List', 'Quickfix List'
  " :prefix: String - What prefix vim uses to close/open the list - 'l', 'q'
  let buflist = s:GetBufferList()

  " Find a buffer number corresponding to the bufname given
  let bufnumbers = map(filter(split(buflist, "\n"), 'v:val =~ "'.a:bufname.'"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
  for bufnum in bufnumbers
    " If it is found, close it and return
    if bufwinnr(bufnum) != -1
      execute(a:prefix . 'close')
      return
    endif
  endfor

  " Guard for empty location list
  if a:prefix ==# 'l' && len(getloclist(0)) == 0
    echo 'Location List is Empty.'
    return
  endif

  let winnr = winnr()
  " Open the list
  execute(a:prefix . 'open')
  if winnr() != winnr
    wincmd p
  endif
endfunction
