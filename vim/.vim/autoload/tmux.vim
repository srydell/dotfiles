if exists('g:autoloaded_srydell_tmux')
  finish
endif
let g:autoloaded_srydell_tmux = 1

" Call last vimux command if exists otherwise prompt for one
function! tmux#VimuxRunLastCommandIfExists() abort
  if exists('g:VimuxRunnerIndex')
    VimuxRunLastCommand
  else
    VimuxPromptCommand
  endif
endfunction

