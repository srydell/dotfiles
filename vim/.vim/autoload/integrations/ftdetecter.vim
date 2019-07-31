function! integrations#ftdetecter#runftdetecter(path, initialFiletype) abort
  let ft_binary = g:integrations_dir . '/bin/ftdetecter'
  if executable(ft_binary)
    return system(ft_binary . ' --path ' . a:path . ' --filetype ' . a:initialFiletype)
  endif
  return ''
endfunction
