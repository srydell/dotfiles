" This function should be called from an autocmd
function! extra_filetypes#cpp#set_special_filetype() abort
  let ft_binary = g:integrations_dir . 'bin/get_special_filetype'
  if executable(ft_binary)
    let extra_ft = system(ft_binary . ' --path ' . expand('%:p') . ' --filetype cpp')
    if len(extra_ft) != 0
      execute('setlocal filetype=cpp.' . extra_ft)
    endif
  endif
endfunction
