" function filename#funcname() abort
"    echo "Done!"
" endfunction

function! getPaths#EditFtplugin() abort
	let s:command = "~/.vim/ftplugin/" . &ft . ".vim"
	execute(":e" . s:command)
endfunction

