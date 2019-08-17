if exists('g:autoloaded_vimnout')
  finish
endif
let g:autoloaded_vimnout = 1

function! vimnout#FilterAndRunCommand(command) abort
  " Call a:command with execute() with caveats:
  " * a:command will be searched for:
  "     * {filetype} - Replaced with all filetypes (might be more separated with a .), otherwise ''
  "     * {compiler} - Replaced with b:current_compiler if exists, otherwise ''
  "     * {files} - Replaced with all files in the resulting directory when
  "         removed '{files}'. E.g. if a:command = ':edit /path/to/{files}', then
  "         all the files in the directory '/path/to/' will be expanded. Otherwise ''
  " * Any buffers entered will be saved and deleted upon leaving if they're not empty
  "
  " :command: String - Will be called with execute.

  " NOTE: {files} should be the last filter
  "       since it will assume some part of the command is a path
  let l:tokens_and_filters = [
        \   ['{filetype}', function('s:FiletypeFilter')],
        \   ['{compiler}', function('s:CompilerFilter')],
        \   ['{files}', function('s:FilesFilter')],
        \ ]

  let l:all_commands = [a:command]
  for [l:token, l:Filter] in l:tokens_and_filters
    if match(a:command, l:token) != -1
      let l:all_commands = l:Filter(l:all_commands, l:token)
    endif
  endfor

  execute(s:GetAutocompletedCommand(l:all_commands))

  if !exists('g:vimnout_delete_on_leave')
    let g:vimnout_delete_on_leave = 1
  endif
  if g:vimnout_delete_on_leave == 1
    " Note: Assumes that this function will open a new buffer.
    "       Otherwise this will be applied to the current buffer and will
    "       (maybe, but probably not) cause damage
    augroup VimNOutWriteBufferOnLeave
      autocmd! * <buffer>
      autocmd BufLeave <buffer> call s:QuitAndWriteIfNotEmpty()
    augroup END
  endif
endfunction

function! s:QuitAndWriteIfNotEmpty() abort
  " Cleanup so that the next time the buffer is entered through a simple edit
  " it is not deleted on leave
  autocmd! VimNOutWriteBufferOnLeave
  if line('$') > 1 && getline(1) !=# ''
    write
  endif
  bdelete
endfunction

function! s:FiletypeFilter(commands, token) abort
  let l:filtered_commands = []
  for l:command in a:commands
    if len(&filetype) != 0
      for l:ft in split(&filetype, '\.')
        let l:filtered_commands += [substitute(l:command, a:token, l:ft, 'g')]
      endfor
      " Strictly from my own convention, since I have filetypes as
      " <vim provided ft>.<my own special ft>
      " I want it to give autocompletions to my own filetype first
      call reverse(l:filtered_commands)
    else
      " Substitute for an empty string
      let l:filtered_commands += [substitute(l:command, a:token, '', 'g')]
    endif
  endfor
  return l:filtered_commands
endfunction

function! s:CompilerFilter(commands, token) abort
  let l:filtered_commands = []
  for l:command in a:commands
    " Handle not defined b:current_compiler
    let l:compiler = exists('b:current_compiler') ? b:current_compiler : ''
    let l:filtered_commands += [substitute(l:command, a:token, l:compiler, 'g')]
  endfor
  return l:filtered_commands
endfunction

function! s:FilesFilter(commands, token) abort
  let l:filtered_commands = []
  for l:command in a:commands
    " Assume the command is on the form '{edit-command} /path/to/{files}'
    " Maybe limiting, but has not found it to be yet
    let l:possible_path = substitute(split(l:command)[-1], a:token, '', 'g')
    if isdirectory(expand(l:possible_path))
      for l:file in split(globpath(l:possible_path, '*'), '\n')
        let l:filtered_commands += filereadable(l:file) ?
              \ [substitute(l:command, a:token, fnamemodify(l:file, ':t'), 'g')]
              \ : []
      endfor
    endif
  endfor
  return l:filtered_commands
endfunction

function! s:GetAutocompletedCommand(possibleCommands) abort
  if len(a:possibleCommands) == 1
    " Nothing to autocomplete
    return a:possibleCommands[0]
  endif

  let l:command = ''
  if exists('*fzf#run')
    let l:commands = fzf#run({'source': a:possibleCommands, 'down': '40%'})
    " Handle if the user presses <C-C> during completion
    let l:command = len(l:commands) != 0 ? l:commands[0] : ''
  else
    " Fallback to inputlist when fzf is not available

    " Local function to provide autocompletions
    let g:editConfigCurrentAutcompleteCommands = a:possibleCommands
    function! ListCommands(ArgLead, CmdLine, CursorPos) abort
      return g:editConfigCurrentAutcompleteCommands
    endfunction

    call inputsave()
    let l:command = input('Which command do you want to run? <TAB> between them. ',
          \ a:possibleCommands[-1],
          \ 'customlist,ListCommands')
    call inputrestore()

    " Lets not clutter
    unlet g:editConfigCurrentAutcompleteCommands
  endif

  return l:command
endfunction
