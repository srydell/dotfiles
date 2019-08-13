if exists('g:autoloaded_srydell_cpp')
  finish
endif
let g:autoloaded_srydell_cpp = 1

" Helper function
function! s:TrySetDetectedFt(filepath) abort
  if len(a:filepath) == 0
    return
  endif

  let extra_ft = integrations#fmdetect#RunFmdetect(a:filepath, 'cpp')
  if len(extra_ft) != 0
    execute('setlocal filetype+=.' . extra_ft)
    return v:true
  endif
  return v:false
endfunction

" This function should be called from an autocmd
function! extra_filetypes#cpp#SetSpecialFiletype() abort
  call s:TrySetDetectedFt(expand('%:p'))
endfunction

function! extra_filetypes#cpp#CheckForSimilarFiles() abort
  " All cpp files in the opened directory
  call s:TrySetDetectedFt(split(globpath(expand('%:h'), '*.{cpp,cxx,cc}'), '\n'))
endfunction
