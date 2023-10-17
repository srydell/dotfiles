if exists('b:did_after_ftplugin_elixir')
  finish
endif
let b:did_after_ftplugin_elixir = 1

" Default compilers. Use binding to toggle between them
let b:valid_compilers = ['elixir', 'mix', 'exunit']

if !exists('current_compiler')
  execute('compiler ' . b:valid_compilers[0])
endif
