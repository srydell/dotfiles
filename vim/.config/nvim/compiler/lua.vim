if exists('current_compiler')
  finish
endif
let current_compiler = 'lua'

let s:cpo_save = &cpoptions
set cpoptions&vim

CompilerSet errorformat=%s:\ %f:%l:%m
CompilerSet makeprg=lua\ %

let &cpoptions = s:cpo_save
unlet s:cpo_save
