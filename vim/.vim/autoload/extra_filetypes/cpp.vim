" This function should be called from an autocmd
function! extra_filetypes#cpp#set_special_filetype() abort
  let extra_ft = integrations#ftdetect#runftdetectBinary(expand('%:p'), 'cpp')
  if len(extra_ft) != 0
    execute('setlocal filetype+=.' . extra_ft)
  endif
endfunction

function! extra_filetypes#cpp#check_for_similar_files() abort
  " For all cpp files in the opened directory
  for f in split(globpath(expand('%:h'), '*.cpp'), '\n')
    " Check if file has a special filetype
    let extra_ft = integrations#ftdetect#runftdetectBinary(f, 'cpp')
    if len(extra_ft) != 0
      " If it has, this file probably has that too
      execute('setlocal filetype+=.' . extra_ft)
      return
    endif
  endfor
endfunction
