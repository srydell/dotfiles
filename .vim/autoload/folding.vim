scriptencoding utf-8

" So that a terminal without utf-8 can read the code
let s:midDot='·'
let s:doubleRightBracket='»'
let s:small_l='ℓ'

" Override default `foldtext()`, which produces something like:
"
"   +---  2 lines: source $HOME/.vim/autoload/folding.vim --------------------------------
"
" Instead returning:
"
"   »··[2ℓ]··: source $HOME/.vim/autoload/folding.vim···································
"
function! folding#foldtext() abort

	" Get the number of lines folded x and concatenate to [xl]
	let l:lines='[' . (v:foldend - v:foldstart + 1) . s:small_l . ']'

	" Get the fold text
	let l:first=substitute(getline(v:foldstart), '\v *', '', '')

	" The number of dots after the bracket will be the fold level
	let l:dashes=substitute(v:folddashes, '-', s:midDot, 'g')

	return s:doubleRightBracket . s:midDot . s:midDot . l:lines . l:dashes . ': ' . l:first
endfunction

" Move to the next closed fold
function! folding#NextClosedFold(dir) abort
	let cmd = 'norm!z' . a:dir
	let view = winsaveview()
	let [l0, l, open] = [0, view.lnum, 1]
	while l != l0 && open
		exe cmd
		let [l0, l] = [l, line('.')]
		let open = foldclosed(l) < 0
	endwhile
	if open
		call winrestview(view)
	endif
endfunction
