" This is all the general options for integrations
" or 'things that tools used from vim needs'

if !exists('g:integrations_dir')
  let g:integrations_dir = expand('~/.vim/integrations/')
endif

" For python helpers
if has('python3') && executable('python3')
  " Setup a virtualenv for python executables
  if !exists('g:integrations_virtualenv')
    let g:integrations_virtualenv = g:integrations_dir . 'venv'
  endif

  if !isdirectory(g:integrations_virtualenv)
    " Firt time setup a virtualenv
    execute(':!python3 -m venv ' . g:integrations_virtualenv)
    echom 'Created virtualenv in directory: ' . g:integrations_virtualenv

    " Install dependencies
    let pip_executable = g:integrations_virtualenv . '/bin/pip'
    let python_packages = ['black', 'cmake-format', 'vim-vint']
    execute('silent !' . pip_executable . ' install ' . join(python_packages, ' '))

    echom 'Installed python dependencies: ' . join(python_packages, ', ')

    " Link them into bin directory
    " vim-vint gives 'vint' executable (an ugly hack =)
    for package in python_packages + ['vint']
      if executable(g:integrations_virtualenv . '/bin/' . package)
        echom 'Linking python executable ' . package . ' to ' . g:integrations_dir . 'bin/' . package
        execute('silent !ln -s ' . g:integrations_virtualenv . '/bin/' . package .
              \ ' ' .
              \ g:integrations_dir . 'bin/' . package)
      endif
    endfor

  endif

  " Black formatting for python
  let g:black_virtualenv = g:integrations_virtualenv
endif
