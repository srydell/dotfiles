if exists('g:autoloaded_srydell_helpDocs')
  finish
endif
let g:autoloaded_srydell_helpDocs = 1

" Function to open a search for the word under the cursor.
" Depending on which filetype is in the current buffer,
" different search engines will be used
function! helpDocs#GetHelpDocs(browser, currentOS) abort
  " Take the least specific filetype
  " Allowing the user to have special filetypes such as 'cmake.cmakelists'
  let l:filetype = split(&filetype, '\.')[0]

  " Special case for vim
  if l:filetype ==# 'vim'
    execute(':help ' . expand('<cword>'))
    return
  endif

  " Optimization to only call system once
  if !exists('g:has_cmake_version_string')
    " Ugly trick to remove ^@ at the end of system() returned string
    let g:has_cmake_version_string = systemlist("cmake --version | head -n 1 | sed 's/[ a-z]//g' | cut -d '.' -f1-2")[0]
  endif

  " Depending on which filetype, use different search engines
  let s:filetypes_and_actions = {
        \ 'cpp': 'http://en.cppreference.com/mwiki/index.php?title=Special%3ASearch&search=SEARCHTERM&button=',
        \ 'cmake': 'https://cmake.org/cmake/help/v' . g:has_cmake_version_string . '/search.html?q=SEARCHTERM&check_keywords=yes&area=default',
        \ 'default': 'https://duckduckgo.com/?q=FILETYPE+SEARCHTERM&ia=qa',
        \}

  " Get the url to open in the browser
  if has_key(s:filetypes_and_actions, l:filetype)
    let s:urlTemplate = s:filetypes_and_actions[l:filetype]
  else
    " Default: Search duckduckgo with filetype wordUnderCursor
    let s:urlTemplate = substitute(s:filetypes_and_actions['default'], 'FILETYPE', l:filetype, 'g')
  endif

  " Expand the word under the cursor and
  " replace 'SEARCHTERM' by the expanded word in urlTemplate
  let s:wordUnderCursor = expand('<cword>')
  let s:url = substitute(s:urlTemplate, 'SEARCHTERM', s:wordUnderCursor, 'g')

  " Build the command to be executed
  " Shold look something like
  " silent ! open -a Safari 'http://www.vim.org'
  let s:cmd = [
        \ 'silent !',
        \ a:currentOS ==# 'Darwin' ? 'open -a' : '',
        \ a:browser,
        \ "'" . s:url . "'"
        \]

  " Same as :cmd
  execute(join(s:cmd))

  " redraw necessary after silent since it wipes the buffer
  redraw!
endfunction
