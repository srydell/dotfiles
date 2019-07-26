function! s:writeAndQuitIfNotEmpty() abort
  if line('$') > 1 && getline(1) !=# ''
    write
  endif
  bdelete
endfunction

function! s:getAutocompletedCommand(possibleCommands) abort
  if len(a:possibleCommands) == 1
    return a:possibleCommands[0]
  endif

  let command = ''
  if exists('*fzf#run')
    let command = fzf#run({'source': a:possibleCommands, 'down': '40%'})[0]
  else
    " Fallback to inputlist
    let index = inputlist(['Which command do you want to run? '] + a:possibleCommands)
    let command = get(a:possibleCommands, index, 'NONE')

    " Error check
    if command ==# 'NONE'
      let command = a:possibleCommands[0]
    endif
  endif

  return command
endfunction

function! editConfig#EditConfig(command, checkForFiletype) abort
  " Call a:command with execute() with caveats:
  " * If a:checkForFiletype is true a:command will have the keyword FILETYPE replaced with the current filetype
  "   and executed as many times as there are filetypes (e.g. filetype=cmake.cmake_module)
  " * Any buffers entered will be saved and deleted upon leaving
  "
  " :command: String - Will be called with execute.
  " :checkForFiletype: Bool - True if the command should be done once per filetype.
  "                          If true, 'FILETYPE' will be replaced in command with the current filetype.
  let command = a:command

  if a:checkForFiletype
    let possibleCommands = []
    for ft in split(&filetype, '\.')
      let possibleCommands += [substitute(a:command, 'FILETYPE', ft, 'g')]
    endfor

    let command = s:getAutocompletedCommand(possibleCommands)
  endif

  execute(command)

  " Note: This will only apply the WriteBufferOnLeave
  "       for the last opened buffer. Close enough.
  augroup WriteBufferOnLeave
    autocmd! * <buffer>
    autocmd BufLeave <buffer> call s:writeAndQuitIfNotEmpty()
  augroup END
endfunction

