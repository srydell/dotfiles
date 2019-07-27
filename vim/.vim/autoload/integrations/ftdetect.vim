function! integrations#ftdetect#runftdetectBinary(path, initialFiletype) abort
  let ft_binary = g:integrations_dir . '/bin/get_special_filetype'
  if executable(ft_binary)
    return system(ft_binary . ' --path ' . a:path . ' --filetype ' . a:initialFiletype)
  endif
  return ''
endfunction
