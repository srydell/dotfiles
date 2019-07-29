let g:projectionist_heuristics = {
      \   'test/*.cpp|src/*.cpp|include/*.h': {
      \     'src/*.cpp': {
      \       'alternate': [
      \         'test/{}.cpp',
      \         'include/{}.h',
      \       ],
      \       'type': 'source'
      \     },
      \     'test/*.cpp': {
      \       'alternate': 'src/{}.cpp',
      \       'skeleton': 'test',
      \       'type': 'source'
      \     },
      \     'include/*.h': {
      \       'alternate': 'src/{}.cpp',
      \       'skeleton': 'header',
      \       'type': 'header'
      \     },
      \   },
      \   'ftdetect/*.vim': {
      \     'ftdetect/*.vim': {
      \       'skeleton': 'ftdetect'
      \     },
      \   }
      \ }
