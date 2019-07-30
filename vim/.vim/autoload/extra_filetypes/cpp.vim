" Helper function

function! s:trySetDetectedFt(filepath) abort
  let extra_ft = integrations#ftdetect#runftdetecterBinary(a:filepath, 'cpp')
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
  " For all cpp files in the opened directory
  for f in split(globpath(expand('%:h'), '*.{cpp,cxx,cc}'), '\n')
    if s:trySetDetectedFt(f)
      return
    endif
  endfor
endfunction
