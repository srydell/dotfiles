" Helper function

function! s:trySetDetectedFt(filepath) abort
  if len(a:filepath) == 0
    return
  endif

  let extra_ft = integrations#ftdetector#runftdetector(a:filepath, 'cpp')
  if len(extra_ft) != 0
    execute('setlocal filetype+=.' . extra_ft)
    return v:true
  endif
  return v:false
endfunction

" This function should be called from an autocmd
function! extra_filetypes#cpp#set_special_filetype() abort
  call s:trySetDetectedFt(expand('%:p'))
endfunction

function! extra_filetypes#cpp#check_for_similar_files() abort
  " All cpp files in the opened directory
  call s:trySetDetectedFt(split(globpath(expand('%:h'), '*.{cpp,cxx,cc}'), '\n'))
endfunction
