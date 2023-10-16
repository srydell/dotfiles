if exists('g:autoloaded_srydell_cpp')
  finish
endif
let g:autoloaded_srydell_cpp = 1

" Helper function
function! s:TrySetDetectedFt(filepath) abort
  if len(a:filepath) == 0
    return v:false
  endif

  let l:extra_ft = integrations#fmdetect#RunFmdetect(a:filepath, 'cpp')
  if len(l:extra_ft) != 0
    execute('setlocal filetype+=.' . l:extra_ft)
    return v:true
  endif
  return v:false
endfunction

function! s:CheckForSimilarFiles() abort
  " Check upwards in the directories until from where vim is called
  let l:directories = split(expand('%:h'), '/')[:-1]
  while !empty(directories)
    let l:currentDir = join(directories, '/')
    let l:cppFilesInDir = split(globpath(currentDir, '*.{cpp,cxx,cc}'), '\n')
    if s:TrySetDetectedFt(l:cppFilesInDir)
      return v:true
    endif

    " Go up one level
    let l:directories = directories[:-2]
  endwhile

  return v:false
endfunction

" This function should be called from an autocmd
function! extra_filetypes#cpp#SetSpecialFiletype() abort
  if s:TrySetDetectedFt(expand('%:p'))
    return v:true
  endif
  return s:CheckForSimilarFiles()
endfunction
