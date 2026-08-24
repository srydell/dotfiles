-- Tests for srydell.compiler.helpers.python_parser (see cpp_parser_spec.lua
-- for how to run this suite headlessly).
local python_parser = require('srydell.compiler.helpers.python_parser')

describe('python_parser.parse_traceback_frame', function()
  it('parses a traceback frame line', function()
    local item = python_parser.parse_traceback_frame('  File "/private/tmp/pytest.py", line 3, in <module>')
    assert.are.same({ filename = '/private/tmp/pytest.py', lnum = 3, text = '<module>' }, item)
  end)

  it('returns nil for unrelated lines', function()
    assert.is_nil(python_parser.parse_traceback_frame('Traceback (most recent call last):'))
    assert.is_nil(python_parser.parse_traceback_frame('ValueError: boom'))
    assert.is_nil(python_parser.parse_traceback_frame('    foo()'))
  end)
end)

describe('python_parser.new_parser', function()
  it('reports every frame in a traceback', function()
    local parser = python_parser.new_parser()
    for _, line in ipairs({
      'Traceback (most recent call last):',
      '  File "/private/tmp/pytest.py", line 3, in <module>',
      '    foo()',
      '    ~~~^^',
      '  File "/private/tmp/pytest.py", line 2, in foo',
      '    raise ValueError("boom")',
      'ValueError: boom',
    }) do
      parser:parse(line)
    end
    local diagnostics = parser:get_result().diagnostics
    assert.are.equal(2, #diagnostics)
    assert.are.equal(3, diagnostics[1].lnum)
    assert.are.equal(2, diagnostics[2].lnum)
    assert.are.equal('E', diagnostics[1].type)
  end)

  it('reports zero diagnostics for clean output', function()
    local parser = python_parser.new_parser()
    parser:parse('hello world')
    assert.are.same({}, parser:get_result().diagnostics)
  end)
end)
