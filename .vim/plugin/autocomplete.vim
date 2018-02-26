function! g:UltiSnips_Complete()
	" Try to expand snippet on tab
	call UltiSnips#ExpandSnippet()
	" If failed
	if g:ulti_expand_res == 0
		" Autocompletion suggestions is visible
		" and expansion failed so go to next suggestion
		if pumvisible()
			return "\<C-n>"
		else
			call UltiSnips#JumpForwards()
			if g:ulti_jump_forwards_res == 0
				return "\<TAB>"
			endif
		endif
	endif
	return ""
endfunction

function! g:UltiSnips_Reverse()
	call UltiSnips#JumpBackwards()
	" If expansion failed go to previous suggestion
	if g:ulti_jump_backwards_res == 0
		return "\<C-p>"
	endif

	return ""
endfunction


if !exists("g:UltiSnipsJumpForwardTrigger")
	let g:UltiSnipsJumpForwardTrigger = "<TAB>"
endif

if !exists("g:UltiSnipsJumpBackwardTrigger")
	let g:UltiSnipsJumpBackwardTrigger = "<S-TAB>"
endif

augroup UltiSnipsMappings
	autocmd!
	" Map expand and jump forward to whatever UltiSnips_Complete() returns
	autocmd InsertEnter * exec "inoremap <silent> " . g:UltiSnipsExpandTrigger     . " <C-R>=g:UltiSnips_Complete()<CR>"
	" Map jump backward to whatever UltiSnips_Reverse() returns
	autocmd InsertEnter * exec "inoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <C-R>=g:UltiSnips_Reverse()<CR>"
augroup END

" Where Ultisnips searches for snippet files
let g:UltiSnipsSnippetDirectories = ["~/.vim/snips", "snips"]

" Where to open split on :UltiSnipsEdit
let g:UltisnipsEditSplit = "vertical"

" Always use Python 3
let g:UltisnipsUsePythonVersion = 3
let g:ycm_python_binary_path = 'python3'

" Don't open a buffer containing information about the completion
let g:ycm_add_preview_to_completeopt = 0
set completeopt-=preview

let g:ycm_global_ycm_extra_conf = "~/.ycm_extra_conf.py"

" Use ctags files for autocompletion
let g:ycm_collect_identifiers_from_tags_files = 1

" Cycle setting for completion
let g:ycm_key_list_select_completion = ['<TAB>', '<Down>']
let g:ycm_key_list_previous_completion = ['<S-TAB>', '<Up>']
