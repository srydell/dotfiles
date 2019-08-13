" Call last vimux command if exists otherwise prompt for one
function! tmux#VimuxRunLastCommandIfExists() abort
  if exists('g:VimuxRunnerIndex')
    VimuxRunLastCommand
  else
    VimuxPromptCommand
  endif
endfunction

