" Edit the specific ftplugin file for the current filetype
function! utils#EditFtplugin() abort
  let s:command = '~/.vim/ftplugin/' . &filetype . '.vim'
  execute(':e' . s:command)
endfunction

function! GetBufferList()
  redir =>buflist
  silent! ls!
  redir END
  return buflist
endfunction

function! utils#ToggleList(bufname, prefix) abort
  " :bufname: String - 'Location List', 'Quickfix List'
  " :prefix: String - What prefix vim uses to close/open the list - 'l', 'q'
  let buflist = GetBufferList()

  " Find a buffer nummer corresponding to the bufname given
  for bufnum in map(filter(split(buflist, "\n"), 'v:val =~ "'.a:bufname.'"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
    " If it is found, close it and return
    if bufwinnr(bufnum) != -1
      execute(a:prefix . 'close')
      return
    endif
  endfor

  " Guard for empty location list
  if a:prefix ==# 'l' && len(getloclist(0)) == 0
    echohl ErrorMsg
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
