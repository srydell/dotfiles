function! s:writeAndQuitIfNotEmpty() abort
  if line('$') > 1 && getline(1) !=# ''
    write
  endif
  bdelete
endfunction

function! utils#EditConfig(command, shouldCallPerFt) abort
  " Call a:command with execute() with caveats:
  " * If shouldCallPerFt is true a:command will have the keyword FILETYPE replaced with the current filetype
  "   and executed as many times as there are filetypes (e.g. filetype=cmake.cmake_module)
  " * Any buffers entered will be saved and deleted upon leaving
  "
  " :command: String - Will be called with execute.
  " :shouldCallPerFt: Bool - True if the command should be done once per filetype.
  "                          If true, 'FILETYPE' will be replaced in command with the current filetype.
  if a:shouldCallPerFt
    for ft in split(&filetype, '\.')
      execute(substitute(a:command, 'FILETYPE', ft, 'g'))
    endfor
  else
    execute(a:command)
  endif

  " Note: This will only apply the WriteBufferOnLeave
  "       for the last opened buffer. Close enough.
  augroup WriteBufferOnLeave
    autocmd! * <buffer>
    autocmd BufLeave <buffer> call s:writeAndQuitIfNotEmpty()
  augroup END
endfunction

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
