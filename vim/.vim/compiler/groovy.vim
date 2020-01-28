if exists('current_compiler')
  finish
endif
let current_compiler = 'groovy'

let s:cpo_save = &cpoptions
set cpoptions&vim

CompilerSet errorformat=''

CompilerSet makeprg=groovy\ %:p

let &cpoptions = s:cpo_save
unlet s:cpo_save

finish " Add example output after this line
