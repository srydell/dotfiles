if exists('g:loaded_srydell_vimnout')
  finish
endif
let g:loaded_srydell_vimnout = 1

command -nargs=* VimNOut call editConfig#EditConfig(<q-args>)
