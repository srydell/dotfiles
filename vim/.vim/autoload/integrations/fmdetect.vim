if exists('g:autoloaded_srydell_fmdetect')
  finish
endif
let g:autoloaded_srydell_fmdetect = 1

function! integrations#fmdetect#RunFmdetect(path, initialFiletype) abort
  let l:fm_binary = g:integrations_dir . '/bin/fmdetect'
  " Allow multiple files to be read in one system call
  let l:parsed_paths = type(a:path) == type([]) ? join(a:path, ',') : a:path
  if executable(l:fm_binary)
    return system(l:fm_binary . ' --paths ' . l:parsed_paths . ' --filetype ' . a:initialFiletype)
  endif
  return ''
endfunction
