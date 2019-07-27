" Check if any of the files in the same directory
" can give us info about the new file
autocmd BufNewFile *.cpp execute('call extra_filetypes#' . &filetype . '#check_for_similar_files()')
