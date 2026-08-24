-- Tests for srydell.compiler.helpers.lua_parser (see cpp_parser_spec.lua
-- for how to run this suite headlessly).
local lua_parser = require('srydell.compiler.helpers.lua_parser')

describe('lua_parser.parse_diagnostic', function()
  it('parses an uncaught lua error', function()
    local item = lua_parser.parse_diagnostic('lua: /tmp/luatest.lua:2: boom')
    assert.are.same({ filename = '/tmp/luatest.lua', lnum = 2, text = 'boom' }, item)
  end)

  it('returns nil for unrelated lines', function()
    assert.is_nil(lua_parser.parse_diagnostic('stack traceback:'))
    assert.is_nil(lua_parser.parse_diagnostic('hello world'))
  end)
end)

describe('lua_parser.new_parser', function()
  it('reports the error line and ignores the traceback', function()
    local parser = lua_parser.new_parser()
    for _, line in ipairs({
      'lua: /tmp/luatest.lua:2: boom',
      'stack traceback:',
      "\t[C]: in global 'error'",
      "\t/tmp/luatest.lua:2: in local 'foo'",
    }) do
      parser:parse(line)
    end
    local diagnostics = parser:get_result().diagnostics
    assert.are.equal(1, #diagnostics)
    assert.are.equal('/tmp/luatest.lua', diagnostics[1].filename)
    assert.are.equal(2, diagnostics[1].lnum)
    assert.are.equal('E', diagnostics[1].type)
  end)

  it('reports zero diagnostics for clean output', function()
    local parser = lua_parser.new_parser()
    parser:parse('hello world')
    assert.are.same({}, parser:get_result().diagnostics)
  end)
end)
