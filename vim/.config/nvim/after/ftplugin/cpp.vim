" Default compilers. Use binding to toggle between them
if match(expand('%:p'), '\Cproto\(type\)\?s\?') != -1
  let b:valid_compilers = ['proto_clang++', 'proto_g++']
else
  let b:valid_compilers = ['nasdaq_cpp', 'cmake_clang_debug', 'cmake_clang_release', 'ctest']
endif

if !exists('current_compiler')
  execute('compiler ' . b:valid_compilers[0])
endif
