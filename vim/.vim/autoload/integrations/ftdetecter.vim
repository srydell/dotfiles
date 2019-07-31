function! integrations#ftdetecter#runftdetecter(path, initialFiletype) abort
  let ft_binary = g:integrations_dir . '/bin/ftdetecter'
  " Allow multiple files to be read in one system call
  let parsed_paths = type(a:path) == type([]) ? join(a:path, ',') : a:path
  if executable(ft_binary)
    return system(ft_binary . ' --paths ' . parsed_paths . ' --filetype ' . a:initialFiletype)
  endif
  return ''
endfunction
