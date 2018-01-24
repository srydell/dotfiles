" Edit the specific ftplugin file for the current filetype
function! functions#EditFtplugin() abort
	let s:command = "~/.vim/ftplugin/" . &ft . ".vim"
	execute(":e" . s:command)
endfunction
