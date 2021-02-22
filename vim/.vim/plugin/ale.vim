if exists('g:loaded_srydell_ale')
  finish
endif
let g:loaded_srydell_ale = 1

set encoding=utf-8
scriptencoding utf-8

let g:ale_c_parse_compile_commands = 1

let g:ale_fixers = {
      \ 'cmake': ['cmakeformat'],
      \ 'elixir': ['mix_format'],
      \ 'javascript': ['prettier'],
      \ 'html': ['html-beautify'],
      \}

let g:ale_linters = {
      \ 'cmake': ['cmakelint'],
      \ 'cpp': ['cppcheck'],
      \ 'javascript': ['eslint'],
      \ 'python': ['pylint'],
      \ }

let g:ale_fix_on_save = 1

" cmake-format shouldn't touch the comments
if filereadable('.cmake-format.yaml')
  let g:ale_cmake_cmakeformat_options = '-c .cmake-format.yaml'
else
  let g:ale_cmake_cmakeformat_options = '--enable-markup false'
endif
let g:ale_cmake_cmakelint_options = g:ale_cmake_cmakeformat_options

" Appear in the left bar
let g:ale_sign_error = '●'
let g:ale_sign_warning = '⚠'

" Use the loclist (like a local quicklist) to show errors
let g:ale_set_loclist = 1
let g:ale_set_quickfix = 0

" Open list in a vim split (default: horizontal)
let g:ale_open_list = 0
let g:ale_list_vertical = 0

" How many lines of errors are shown (default: 10)
let g:ale_list_window_size = 5

" Let autocompletion plugins do the autocompletion
let g:ale_completion_enabled = 0

" Guess that the compile_commands.json is in ./build
" Otherwise, the linter will use some default flags
" NOTE: Available linters are set in .vim/ftplugin/cpp.vim
let g:ale_c_build_dir = './build/'
