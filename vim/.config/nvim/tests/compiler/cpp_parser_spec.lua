-- Tests for srydell.compiler.helpers.cpp_parser, the pure-Lua replacement
-- for the old vim-errorformat-based clang/gcc output parsing.
--
-- Run (from the nvim config root):
--   nvim --headless -u NONE -c "lua \
--     vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/lazy/plenary.nvim'); \
--     vim.opt.runtimepath:append(vim.fn.getcwd()); \
--     require('plenary.test_harness').test_directory('tests/', { minimal_init = 'tests/minimal_init.lua' })" \
--     -c 'qa'
local cpp_parser = require('srydell.compiler.helpers.cpp_parser')

describe('cpp_parser.parse_diagnostic_with_column', function()
  it('parses a clang/gcc error with a column', function()
    local item = cpp_parser.parse_diagnostic_with_column("src/foo.cpp:12:5: error: use of undeclared identifier 'x'")
    assert.are.same({
      filename = 'src/foo.cpp',
      lnum = 12,
      col = 5,
      type = 'E',
      text = "use of undeclared identifier 'x'",
    }, item)
  end)

  it('parses a warning', function()
    local item =
      cpp_parser.parse_diagnostic_with_column("src/foo.cpp:20:10: warning: unused variable 'y' [-Wunused-variable]")
    assert.are.equal('W', item.type)
    assert.are.equal(20, item.lnum)
    assert.are.equal(10, item.col)
  end)

  it('returns nil for unrelated lines', function()
    assert.is_nil(cpp_parser.parse_diagnostic_with_column('[184/747] Compiling src/api/session.cpp'))
    assert.is_nil(cpp_parser.parse_diagnostic_with_column("'build' finished successfully (53.320s)"))
  end)
end)

describe('cpp_parser.parse_diagnostic_no_column', function()
  it('parses a diagnostic without a column', function()
    local item = cpp_parser.parse_diagnostic_no_column("src/foo.cpp:12: error: 'x' was not declared in this scope")
    assert.are.same({
      filename = 'src/foo.cpp',
      lnum = 12,
      type = 'E',
      text = "'x' was not declared in this scope",
    }, item)
  end)

  it('returns nil for a line with a column (handled by the other parser)', function()
    assert.is_nil(cpp_parser.parse_diagnostic_no_column('src/foo.cpp:12:5: error: bad'))
  end)
end)

describe('cpp_parser.parse_linker_error', function()
  it('parses an undefined reference from ld', function()
    local item = cpp_parser.parse_linker_error("src/foo.cpp:(.text+0x1a): undefined reference to `bar()'")
    assert.are.same({
      filename = 'src/foo.cpp',
      type = 'E',
      text = "undefined reference to `bar()'",
    }, item)
  end)

  it('returns nil for non-linker lines', function()
    assert.is_nil(cpp_parser.parse_linker_error('src/foo.cpp:12:5: error: bad'))
  end)
end)

describe('cpp_parser.is_suppressed_noise', function()
  it('recognizes both gcc "each undeclared identifier" noise lines', function()
    assert.is_true(
      cpp_parser.is_suppressed_noise(
        'src/foo.cpp:12: error: (Each undeclared identifier is reported only once for each function it appears in.)'
      )
    )
    assert.is_true(cpp_parser.is_suppressed_noise('src/foo.cpp:12: error: for each function it appears in.)'))
  end)

  it('does not suppress real diagnostics', function()
    assert.is_false(cpp_parser.is_suppressed_noise('src/foo.cpp:12:5: error: bad'))
  end)
end)

describe('cpp_parser.match_directory_change', function()
  it('recognizes waf/make Entering directory announcements', function()
    local change, dir = cpp_parser.match_directory_change("Waf: Entering directory `/home/user/build/debug'")
    assert.are.equal('enter', change)
    assert.are.equal('/home/user/build/debug', dir)
  end)

  it('recognizes make Leaving directory announcements', function()
    local change, dir = cpp_parser.match_directory_change("make[1]: Leaving directory '/home/user/build'")
    assert.are.equal('leave', change)
    assert.are.equal('/home/user/build', dir)
  end)

  it('returns nil for unrelated lines', function()
    local change = cpp_parser.match_directory_change('[184/747] Compiling src/api/session.cpp')
    assert.is_nil(change)
  end)
end)

describe('cpp_parser.new_parser', function()
  local function feed(parser, lines)
    for _, line in ipairs(lines) do
      parser:parse(line)
    end
    return parser:get_result().diagnostics
  end

  it('reports a simple diagnostic', function()
    local parser = cpp_parser.new_parser()
    local diagnostics = feed(parser, { "src/foo.cpp:12:5: error: use of undeclared identifier 'x'" })
    assert.are.equal(1, #diagnostics)
    assert.are.equal('src/foo.cpp', diagnostics[1].filename)
  end)

  it('resolves relative filenames against the current directory-context', function()
    local parser = cpp_parser.new_parser()
    local diagnostics = feed(parser, {
      "Waf: Entering directory `/home/user/build/debug'",
      'src/foo.cpp:12:5: error: bad',
      "Waf: Leaving directory `/home/user/build/debug'",
    })
    assert.are.equal(1, #diagnostics)
    assert.are.equal('/home/user/build/debug/src/foo.cpp', diagnostics[1].filename)
  end)

  it('does not prefix already-absolute filenames', function()
    local parser = cpp_parser.new_parser()
    local diagnostics = feed(parser, {
      "Waf: Entering directory `/home/user/build/debug'",
      '/abs/src/foo.cpp:12:5: error: bad',
    })
    assert.are.equal('/abs/src/foo.cpp', diagnostics[1].filename)
  end)

  it('pops nested directories correctly on Leaving', function()
    local parser = cpp_parser.new_parser()
    local diagnostics = feed(parser, {
      "Waf: Entering directory `/a'",
      "Waf: Entering directory `/a/b'",
      "Waf: Leaving directory `/a/b'",
      'src/foo.cpp:1:1: error: bad',
    })
    assert.are.equal('/a/src/foo.cpp', diagnostics[1].filename)
  end)

  it('suppresses gcc duplicate-identifier noise lines', function()
    local parser = cpp_parser.new_parser()
    local diagnostics = feed(parser, {
      "src/foo.cpp:1:1: error: 'x' was not declared in this scope",
      'src/foo.cpp:1: error: (Each undeclared identifier is reported only once',
      'src/foo.cpp:1: error: for each function it appears in.)',
    })
    assert.are.equal(1, #diagnostics)
  end)

  it('reports zero diagnostics for the user-reported successful docker/waf build', function()
    -- Regression test: this exact output (a successful `docker run` build of
    -- 'all' targets) used to spuriously open the quickfix window because a
    -- loose vim errorformat matched pty/ninja-progress noise mid-stream.
    local parser = cpp_parser.new_parser()
    local diagnostics = feed(parser, {
      'Building all targets',
      'Adding conan targets...',
      'Build commands will be stored in build/debug/compile_commands.json',
      "Waf: Entering directory `/Users/simryd/code/dsf/build/debug'",
      'Adding conan targets...',
      '[184/747] Compiling src/api/descriptor_table.cpp',
      '[510/747] Compiling src/api/client/test/test_client.cpp',
      '[512/747] Compiling src/api/client/test/test_sharq_client.cpp',
      '[523/747] Compiling src/api/test/test_descriptor_table.cpp',
      '[629/747] Compiling src/api/session.cpp',
      '[630/747] Compiling src/api/api.cpp',
      '[686/747] Compiling src/api/test/test_session.cpp',
      '[687/747] Compiling src/api/test/test_api_impl.cpp',
      '[733/747] Linking build/debug/lib/libdsfapi.so',
      '[734/747] Linking build/debug/bin/unit_test_dsf_api_processor',
      '[735/747] Linking build/debug/bin/unit_test_dsf_test_func',
      '[736/747] Linking build/debug/lib/libdsf_bindings_jni.so',
      '[737/747] Linking build/debug/bin/dsf_api_tests',
      '[738/747] Linking build/debug/bin/dsfctl_tests',
      '[739/747] Linking build/debug/bin/func_test_dsf',
      '[740/747] Linking build/debug/bin/geniumperf',
      '[741/747] Linking build/debug/bin/wod_verifier',
      '[742/747] Linking build/debug/bin/dsf_hello_world_writer',
      '[743/747] Linking build/debug/bin/dsf_hello_world_reader',
      '[744/747] Linking build/debug/bin/unit_test_dsf_api',
      "Waf: Leaving directory `/Users/simryd/code/dsf/build/debug'",
      'Test commands will be stored in build/debug/test_commands.json',
      "'build' finished successfully (53.320s)",
      '',
      '[Process exited 0]',
    })
    assert.are.same({}, diagnostics)
  end)
end)
