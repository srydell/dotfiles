" Call last vimux command if exists otherwise prompt for one
function! tmux#vimuxRunLastCommandIfExists() abort
  if exists("g:VimuxRunnerIndex")
    VimuxRunLastCommand
  else
    VimuxPromptCommand
  endif
endfunction

