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

    " Local function to provide autocompletions
    let g:editConfigCurrentAutcompleteCommands = a:possibleCommands
    function! ListCommands(ArgLead, CmdLine, CursorPos) abort
      return g:editConfigCurrentAutcompleteCommands
    endfunction

    call inputsave()
    let command = input('Which command do you want to run? <TAB> between them. ', '', 'customlist,ListCommands')
    call inputrestore()
  endif

  return command
endfunction

function! editConfig#EditConfig(command) abort
  " Call a:command with execute() with caveats:
  " * If a:checkForFiletype is true a:command will have the keyword {filetype} replaced with the current filetype
  "   and executed as many times as there are filetypes (e.g. filetype=cmake.cmake_module)
  " * Any buffers entered will be saved and deleted upon leaving
  "
  " :command: String - Will be called with execute.
  let command = a:command

  let filetypeToken = '{filetype}'
  if match(command, filetypeToken)
    if empty(&filetype)
      echohl WarningMsg | echo 'This file has no filetype detected.' | echohl None
      return
    endif

    let possibleCommands = []
    for ft in split(&filetype, '\.')
      let possibleCommands += [substitute(a:command, '{filetype}', ft, 'g')]
    endfor
    " Strictly from my own convention, since I have filetypes as
    " <vim provided ft>.<my own special ft>
    " I want it to give autocompletions to my own filetype first
    call reverse(possibleCommands)

    let command = s:getAutocompletedCommand(possibleCommands)
  endif

  execute(command)

  " Note: This assumes that this function will open a new buffer.
  "       Otherwise this will be applied to the current buffer and will
  "       (maybe, but probably not) cause damage
  augroup WriteBufferOnLeave
    autocmd! * <buffer>
    autocmd BufLeave <buffer> call s:writeAndQuitIfNotEmpty()
  augroup END
endfunction

