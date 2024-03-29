vim.g.projectionist_heuristics = {
  ['*'] = {
    ['*.in'] = {
      alternate = { '{}' },
    },
    ['include/*.hpp'] = {
      alternate = 'tests/{}.cpp',
      type = 'header',
    },
    ['src/*.cpp'] = {
      alternate = { 'src/{}.hpp', 'src/{}.h', 'include/{}.hpp' },
      type = 'source',
    },
    ['src/*.h'] = {
      alternate = 'src/{}.cpp',
      type = 'header',
    },
    ['src/*.hpp'] = {
      alternate = 'tests/{}.cpp',
      type = 'header',
    },
    ['tests/*.cpp'] = {
      alternate = { 'src/{}.cpp', 'src/{}.hpp' },
      type = 'source',
    },
  },
}
