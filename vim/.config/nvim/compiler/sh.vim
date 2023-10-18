if exists('current_compiler')
  finish
endif
let current_compiler = 'sh'

let s:cpo_save = &cpoptions
set cpoptions&vim

" Usually use cmake to build out of source
" use the default 'errorformat'
CompilerSet errorformat=
      \%f:\ line\ %l:\ %m,
      \%f:\ %l:\ %m

CompilerSet makeprg=if\ [\ \!\ -x\ %:p\ ];\ then\ chmod\ \+x\ %:p;\ fi;\ %:p

let &cpoptions = s:cpo_save
unlet s:cpo_save
finish
" /home/simon/dotfiles/vim/.vim/integrations/compiler/cpp_prototype.sh: 47: /home/simon/dotfiles/vim/.vim/integrations/compiler/cpp_prototype.sh: /home/simon/dotfiles/vim/.vim/build/bin/: Permission denied
