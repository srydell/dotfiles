if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

" http://vim.wikia.com/wiki/Editing_crontab
" Crontab temp files need to be edited in place
setlocal backupcopy=yes
