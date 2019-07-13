if exists('current_compiler')
  finish
endif
let current_compiler = 'python'

let s:cpo_save = &cpoptions
set cpoptions&vim

CompilerSet errorformat=
      \%*\\sFile\ \"%f\"\\,\ line\ %l\\,\ %m,
      \%*\\sFile\ \"%f\"\\,\ line\ %l,
CompilerSet makeprg=python3\ %

let &cpoptions = s:cpo_save
unlet s:cpo_save
