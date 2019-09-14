if exists('current_compiler')
  finish
endif
let current_compiler = 'sh'

let s:cpo_save = &cpoptions
set cpoptions&vim

" Usually use cmake to build out of source
" use the default 'errorformat'
CompilerSet errorformat=%f:\ line\ %l:\ %m

CompilerSet makeprg=if\ [\ \!\ -x\ %:p\ ];\ then\ chmod\ \+x\ %:p;\ fi;\ %:p

let &cpoptions = s:cpo_save
unlet s:cpo_save
