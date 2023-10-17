if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

if !exists('current_compiler')
  compiler groovy
endif
