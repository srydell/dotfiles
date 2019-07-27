let g:projectionist_heuristics = {
      \   'test/*.cpp|src/*.cpp|include/*.h': {
      \     'src/*.cpp': {
      \       'alternate': 'include/{}.h',
      \       'type': 'source'
      \     },
      \     'test/*.cpp': {
      \       'alternate': 'src/{}.h',
      \       'type': 'source'
      \     },
      \     'include/*.h': {
      \       'alternate': 'src/{}.cpp',
      \       'type': 'header'
      \     },
      \   }
      \ }
