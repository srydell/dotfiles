if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" Set comment string to be used by tcomment to !
setlocal commentstring=!\ %s
