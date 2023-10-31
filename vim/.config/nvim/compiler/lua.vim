if exists('current_compiler')
  finish
endif
let current_compiler = 'lua'

let s:cpo_save = &cpoptions
set cpoptions&vim

CompilerSet errorformat=
      \%*\\sFile\ \"%f\"\\,\ line\ %l\\,\ %m,
      \%*\\sFile\ \"%f\"\\,\ line\ %l,
CompilerSet makeprg=lua\ %

let &cpoptions = s:cpo_save
unlet s:cpo_save
