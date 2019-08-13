if exists('g:autoloaded_srydell_editConfig')
  finish
endif
let g:autoloaded_srydell_editConfig = 1

function! s:WriteAndQuitIfNotEmpty() abort
  if line('$') > 1 && getline(1) !=# ''
    write
  endif
  bdelete
endfunction

function! s:GetAutocompletedCommand(possibleCommands) abort
  if len(a:possibleCommands) == 1
    " Nothing to autocomplete
    return a:possibleCommands[0]
  endif

  let command = ''
  if exists('*fzf#run')
    let commands = fzf#run({'source': a:possibleCommands, 'down': '40%'})
    " Handle if the user presses <C-C> during completion
    let command = len(commands) != 0 ? commands[0] : ''
  else
    " Fallback to inputlist when fzf is not available

    " Local function to provide autocompletions
    let g:editConfigCurrentAutcompleteCommands = a:possibleCommands
    function! ListCommands(ArgLead, CmdLine, CursorPos) abort
      return g:editConfigCurrentAutcompleteCommands
    endfunction

    call inputsave()
    let command = input('Which command do you want to run? <TAB> between them. ',
          \ a:possibleCommands[-1],
          \ 'customlist,ListCommands')
    call inputrestore()

    " Lets not clutter
    unlet g:editConfigCurrentAutcompleteCommands
  endif

  return command
endfunction

function! editConfig#EditConfig(command) abort
  " Call a:command with execute() with caveats:
  " * a:command will be searched for:
  "     * {filetype} - Replaced with all filetypes (might be more separated with a .)
  "     * {compiler} - Replaced with b:current_compiler if exists, otherwise ''
  " * Any buffers entered will be saved and deleted upon leaving
  "
  " :command: String - Will be called with execute.
  let extraCommands = []

  let filetypeToken = '{filetype}'
  if match(a:command, filetypeToken) != -1
    for ft in split(&filetype, '\.')
      let extraCommands += [substitute(a:command, filetypeToken, ft, 'g')]
    endfor
    " Strictly from my own convention, since I have filetypes as
    " <vim provided ft>.<my own special ft>
    " I want it to give autocompletions to my own filetype first
    call reverse(extraCommands)
  endif

  let compilerToken = '{compiler}'
  if match(a:command, compilerToken) != -1
    " Handle not defined b:current_compiler
    let compiler = exists('b:current_compiler') ? b:current_compiler : ''
    let extraCommands += [substitute(a:command, compilerToken, compiler, 'g')]
  endif

  let command = empty(extraCommands) ?
        \ a:command :
        \ s:GetAutocompletedCommand(extraCommands)
  execute(command)

  " Note: This assumes that this function will open a new buffer.
  "       Otherwise this will be applied to the current buffer and will
  "       (maybe, but probably not) cause damage
  augroup WriteBufferOnLeave
    autocmd! * <buffer>
    autocmd BufLeave <buffer> call s:WriteAndQuitIfNotEmpty()
  augroup END
endfunction
