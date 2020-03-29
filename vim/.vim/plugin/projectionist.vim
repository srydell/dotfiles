if exists('g:loaded_srydell_projectionist')
  finish
endif
let g:loaded_srydell_projectionist = 1

let g:projectionist_heuristics = {
      \   '*': {
      \     'src/*.cpp': {
      \       'alternate': [
      \         'test/{}.cpp',
      \         'src/{}.hpp',
      \         'include/{}.hpp',
      \       ],
      \       'type': 'source'
      \     },
      \     'tests/*.cpp': {
      \       'alternate': 'src/{}.cpp',
      \       'skeleton': 'test',
      \       'type': 'source'
      \     },
      \     'include/*.hpp': {
      \       'alternate': 'tests/{}.cpp',
      \       'skeleton': 'header',
      \       'type': 'header'
      \     },
      \     'src/*.hpp': {
      \       'alternate': 'tests/{}.cpp',
      \       'skeleton': 'header',
      \       'type': 'header'
      \     },
      \     '*/CMakeLists.txt': {
      \       'skeleton': 'cmakelists'
      \     },
      \     '*/conanfile.txt': {
      \       'skeleton': 'conanfile'
      \     },
      \
      \     '*/README.md': {
      \       'skeleton': 'readme'
      \     },
      \
      \     'plugin/*.vim': {
      \       'skeleton': 'plugin'
      \     },
      \     'ftplugin/*.vim': {
      \       'skeleton': 'ftplugin'
      \     },
      \     'autoload/*.vim': {
      \       'skeleton': 'autoload'
      \     },
      \     'ftdetect/*.vim': {
      \       'skeleton': 'ftdetect'
      \     },
      \
      \     'test_*.py': {
      \       'skeleton': 'unittest'
      \     },
      \   }
      \ }
