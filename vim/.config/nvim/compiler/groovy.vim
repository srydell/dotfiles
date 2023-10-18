if exists('current_compiler')
  finish
endif
let current_compiler = 'groovy'

let s:cpo_save = &cpoptions
set cpoptions&vim

" /path/to/file.groovy: 82: expecting ']', found ')' @ line 82, column 70.
"     ["a", "b", "c") {
CompilerSet errorformat=
      \%f:\ %l:%m

CompilerSet makeprg=groovy\ %:p

let &cpoptions = s:cpo_save
unlet s:cpo_save

finish " Add example output after this line
