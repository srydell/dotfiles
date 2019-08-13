if exists('g:loaded_srydell_lint')
  finish
endif
let g:loaded_srydell_lint = 1

let g:ale_fixers = {'cmake': ['cmakeformat']}
let g:ale_fix_on_save = 1

" Appear in the left bar
let g:ale_sign_error = '>>'
let g:ale_sign_warning = '--'

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
