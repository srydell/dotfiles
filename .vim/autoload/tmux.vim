" Call last vimux command if exists otherwise prompt for one
function! tmux#vimuxRunLastCommandIfExists() abort
	if exists("g:VimuxRunnerIndex")
		let cmd = split(g:VimuxLastCommand)

		" Loop over and expand each substring
		" separated with ' ' in command and expand
		" Note: expand() does nothing if not expandable
		let counter = 0
		for substring in cmd
			let cmd[counter] = expand(substring)
			let counter = counter + 1
		endfor

		" Join the expanded command
		let g:VimuxLastCommand = join(cmd)
		VimuxRunLastCommand
	else
		VimuxPromptCommand
	endif
endfunction

