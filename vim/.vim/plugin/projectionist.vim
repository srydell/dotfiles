let g:projectionist_heuristics = {
      \   'tests/*.cpp|src/*.cpp|include/*.h': {
      \     'src/*.cpp': {
      \       'alternate': [
      \         'test/{}.cpp',
      \         'include/{}.h',
      \       ],
      \       'type': 'source'
      \     },
      \     'tests/*.cpp': {
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
      \
      \   'ftdetect/*.vim': {
      \     'ftdetect/*.vim': {
      \       'skeleton': 'ftdetect'
      \     },
      \   },
      \   '*': {
      \     'test_*.py': {
      \       'skeleton': 'unittest'
      \     },
      \     'conanfile.txt': {
      \       'skeleton': 'conanfile'
      \     },
      \     'CMakeLists.txt': {
      \       'skeleton': 'cmakelists'
      \     },
      \   }
      \ }
