-- Tests for srydell.compiler.helpers.cmake_parser (see cpp_parser_spec.lua
-- for how to run this suite headlessly). Note this module only covers
-- CMake's own configure-time diagnostics -- the C++ build step's output is
-- handled separately by cpp_parser.lua (see cmake_build.lua).
local cmake_parser = require('srydell.compiler.helpers.cmake_parser')

describe('cmake_parser.parse_diagnostic', function()
  it('parses a CMake Error', function()
    local item = cmake_parser.parse_diagnostic('CMake Error at CMakeLists.txt:10 (message):')
    assert.are.same({ type = 'E', filename = 'CMakeLists.txt', lnum = 10 }, item)
  end)

  it('parses a CMake Warning with a (dev) annotation', function()
    local item = cmake_parser.parse_diagnostic('CMake Warning (dev) at src/CMakeLists.txt:5 (find_package):')
    assert.are.same({ type = 'W', filename = 'src/CMakeLists.txt', lnum = 5 }, item)
  end)

  it('returns nil for the free-text continuation lines', function()
    assert.is_nil(cmake_parser.parse_diagnostic('  Some error message here'))
  end)

  it('returns nil for unrelated lines', function()
    assert.is_nil(cmake_parser.parse_diagnostic('-- Configuring done'))
  end)
end)

describe('cmake_parser.new_parser', function()
  it('reports each CMake diagnostic header line', function()
    local parser = cmake_parser.new_parser()
    for _, line in ipairs({
      '-- Configuring done',
      'CMake Error at CMakeLists.txt:10 (message):',
      '  Some error message here',
      'CMake Warning (dev) at src/CMakeLists.txt:5 (find_package):',
      '  Some warning',
    }) do
      parser:parse(line)
    end
    local diagnostics = parser:get_result().diagnostics
    assert.are.equal(2, #diagnostics)
    assert.are.equal('E', diagnostics[1].type)
    assert.are.equal('W', diagnostics[2].type)
  end)

  it('reports zero diagnostics for a clean configure', function()
    local parser = cmake_parser.new_parser()
    parser:parse('-- Configuring done')
    parser:parse('-- Generating done')
    assert.are.same({}, parser:get_result().diagnostics)
  end)
end)
