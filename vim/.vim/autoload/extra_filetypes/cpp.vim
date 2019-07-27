" This function should be called from an autocmd
function! extra_filetypes#cpp#set_special_filetype() abort
  let extra_ft = integrations#ftdetect#runftdetectBinary(expand('%:p'), 'cpp')
  if len(extra_ft) != 0
    execute('setlocal filetype+=.' . extra_ft)
  endif
endfunction
