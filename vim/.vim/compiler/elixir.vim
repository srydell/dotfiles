if exists('current_compiler')
  finish
endif
let current_compiler = 'elixir'

let s:cpo_save = &cpoptions
set cpoptions&vim

CompilerSet errorformat=
      \%Wwarning:\ %m,
      \%C%f:%l,%Z,
      \%E==\ Compilation\ error\ in\ file\ %f\ ==,
      \%C**\ (%\\w%\\+)\ %f:%l:\ %m,%Z,
      \%\\s%\\+%f:%l:\ %m

CompilerSet makeprg=elixir\ %:p

let &cpoptions = s:cpo_save
unlet s:cpo_save

finish " Add example output after this line
