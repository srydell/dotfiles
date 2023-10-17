if !filereadable(expand('~/.vim/syntax/cmake.vim'))
      \ || !filereadable(expand('~/.vim/indent/cmake.vim'))
  call integrations#installation#GetCMakeHelpFiles()
endif
