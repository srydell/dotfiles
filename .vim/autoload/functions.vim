" Edit the specific ftplugin file for the current filetype
function! functions#EditFtplugin() abort
	let s:command = "~/.vim/ftplugin/" . &ft . ".vim"
	execute(":e" . s:command)
endfunction

" Function to open a search for the word under the cursor.
" Depending on which filetype is in the current buffer, different
" search engines will be used
function! functions#OnlineDoc()
	" Depending on which filetype, use different search engines
	" OBS: Use ' instead of " to tell vim to use the string AS IS. Therefore
	" no substitutions to escaped characters are needed
	if &ft =~ "vim"
		execute(":help " . expand("<cword>"))
		return
	elseif &ft =~ "cpp"
		let s:urlTemplate = 'http://en.cppreference.com/mwiki/index.php?title=Special%3ASearch&search=SEARCHTERM&button='
	else
		let s:urlTemplate = 'https://duckduckgo.com/?q=SEARCHTERM'
	endif
	" TODO: Put browser as user specific
	" Requires s:browser to be in PATH
	let s:browser = "qutebrowser"

	let s:wordUnderCursor = expand("<cword>")

	" Replace SEARCHTERM by the selected word
	let s:url = substitute(s:urlTemplate, "SEARCHTERM", s:wordUnderCursor, "g")

	" Same as running ": silent! browser 'url'"
	let s:cmd = "silent !" . s:browser . " '" . s:url . "'"
	execute(s:cmd)
	" redraw necessary after silent since it wipes the buffer
	redraw!
endfunction
