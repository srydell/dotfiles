" Edit the specific ftplugin file for the current filetype
function! utils#EditFtplugin() abort
	let s:command = "~/.vim/ftplugin/" . &ft . ".vim"
	execute(":e" . s:command)
endfunction

function! GetBufferList()
	redir =>buflist
	silent! ls!
	redir END
	return buflist
endfunction

function! utils#ToggleList(bufname, prefix) abort
	" :bufname: String - "Location List", "Quickfix List"
	" :prefix: String - What prefix vim uses to close/open the list - "l", "q"
	let buflist = GetBufferList()

	" Find a buffer nummer corresponding to the bufname given
	for bufnum in map(filter(split(buflist, '\n'), 'v:val =~ "'.a:bufname.'"'), 'str2nr(matchstr(v:val, "\\d\\+"))')
		" If it is found, close it and return
		if bufwinnr(bufnum) != -1
			exec(a:prefix.'close')
			return
		endif
	endfor

	" Guard for empty location list
	if a:prefix == 'l' && len(getloclist(0)) == 0
		echohl ErrorMsg
		echo "Location List is Empty."
		return
	endif

	let winnr = winnr()
	" Open the list
	exec(a:prefix.'open')
	if winnr() != winnr
		wincmd p
	endif
endfunction

" Function to open a search for the word under the cursor.
" Depending on which filetype is in the current buffer,
" different search engines will be used
function! utils#GetHelpDocs(browser, currentOS)
	" Depending on which filetype, use different search engines
	" OBS: Use ' instead of " to tell vim to use the string AS IS.
	" Therefore no substitutions to escaped characters are needed
	" TODO: Make this a dictionary
	if &ft =~ "vim"
		execute(":help " . expand("<cword>"))
		return
	elseif &ft =~ "cpp"
		let s:urlTemplate = 'http://en.cppreference.com/mwiki/index.php?title=Special%3ASearch&search=SEARCHTERM&button='
	else
		let s:urlTemplate = 'https://duckduckgo.com/?q=python+SEARCHTERM&ia=qa'
	endif

	" Expand the word under the cursor and
	" replace 'SEARCHTERM' by the expanded word in urlTemplate
	let s:wordUnderCursor = expand("<cword>")
	let s:url = substitute(s:urlTemplate, "SEARCHTERM", s:wordUnderCursor, "g")

	" Build the command to be executed
	" Shold look something like
	" silent ! open -a Safari 'http://www.vim.org'
	let s:cmd = [
		\ 'silent !',
		\ a:currentOS == 'Darwin' ? 'open -a' : '',
		\ a:browser,
		\ "'" . s:url . "'"
		\]

	" Same as :cmd
	execute(join(s:cmd))

	" redraw necessary after silent since it wipes the buffer
	redraw!
endfunction
