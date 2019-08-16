if exists('g:autoloaded_srydell_installation')
  finish
endif
let g:autoloaded_srydell_installation = 1

if !exists('g:integrations_dir')
  let g:integrations_dir = expand('~/.vim/integrations')
endif

function! integrations#installation#GetPythonPackages() abort
  " Install python packages and link them to g:integrations_dir bin
  " NOTE: Relies on g:integrations_dir and g:integrations_virtualenv
  "       being set beforehand

  " Setup a virtualenv for python executables
  if !exists('g:integrations_virtualenv')
    let g:integrations_virtualenv = g:integrations_dir . '/venv'
  endif

  " First time setup a virtualenv
  execute(':!python3 -m venv ' . g:integrations_virtualenv)
  echom 'Created virtualenv in directory: ' . g:integrations_virtualenv

  " Install dependencies
  let l:pip_executable = g:integrations_virtualenv . '/bin/pip'
  let l:python_packages = ['black', 'cmake-format', 'vim-vint', 'pyls']
  execute('silent !' . l:pip_executable . ' install ' . join(l:python_packages, ' '))

  echom 'Installed python dependencies: ' . join(l:python_packages, ', ')

  " Link them into bin directory
  " vim-vint gives 'vint' executable (an ugly hack =)
  for l:package in l:python_packages + ['vint']
    if executable(g:integrations_virtualenv . '/bin/' . l:package)
      echom 'Linking python executable ' . l:package . ' to ' . g:integrations_dir . '/bin/' . l:package
      execute('silent !ln -s ' . g:integrations_virtualenv . '/bin/' . l:package .
            \ ' ' .
            \ g:integrations_dir . '/bin/' . l:package)
    endif
  endfor
endfunction

function! integrations#installation#GetClangHelper() abort
  let l:url = 'https://llvm.org/svn/llvm-project/cfe/trunk/tools/clang-format/clang-format.py'

  execute '!wget --directory-prefix=' . g:integrations_dir . ' ' . l:url

  echom 'Downloaded clang-format helper script'
endfunction
