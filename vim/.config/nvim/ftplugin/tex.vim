if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" Latex autocompilation
"
" Compile latex with rubber upon saving the file
" TODO: put in sighup to update mupdf automatically using
"	$ pkill -HUP mupdf
"	Must check whether there is an open mupdf running though, maybe even
"	connected to the current buffer would be good
nnoremap <buffer> <leader>c :w<CR>:silent !rubber --pdf --warn all %<CR>:redraw!<CR>
" View PDF. '%:r' is current file's root (base) name
nnoremap <buffer> <leader>v :silent !mupdf %:r.pdf &<CR><CR>

setlocal spell
