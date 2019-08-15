if exists('g:loaded_srydell_integrations')
  finish
endif
let g:loaded_srydell_integrations = 1

" This is all the general options for integrations
" or 'things that tools used from vim needs'

if !exists('g:integrations_dir')
  let g:integrations_dir = expand('~/.vim/integrations')
endif

" For python helpers
if has('python3') && executable('python3')
  " Setup a virtualenv for python executables
  if !exists('g:integrations_virtualenv')
    let g:integrations_virtualenv = g:integrations_dir . '/venv'
  endif

  if !isdirectory(g:integrations_virtualenv)
    call integrations#installation#GetPythonPackages()
  endif

  " Black formatting for python
  let g:black_virtualenv = g:integrations_virtualenv
endif
