-- Tests for srydell.compiler.helpers.perl_parser (see cpp_parser_spec.lua
-- for how to run this suite headlessly).
local perl_parser = require('srydell.compiler.helpers.perl_parser')

describe('perl_parser.parse_diagnostic', function()
  it('parses a syntax error with trailing context', function()
    local item = perl_parser.parse_diagnostic('syntax error at perltest.pl line 3, near "= ;"')
    assert.are.same({ text = 'syntax error', filename = 'perltest.pl', lnum = 3 }, item)
  end)

  it('parses a plain die message', function()
    local item = perl_parser.parse_diagnostic('custom error at perlok.pl line 2.')
    assert.are.same({ text = 'custom error', filename = 'perlok.pl', lnum = 2 }, item)
  end)

  it('returns nil for unrelated lines', function()
    assert.is_nil(perl_parser.parse_diagnostic('hi'))
  end)
end)

describe('perl_parser.is_suppressed_noise', function()
  it('recognizes the compilation-aborted summary line', function()
    assert.is_true(perl_parser.is_suppressed_noise('Execution of perltest.pl aborted due to compilation errors.'))
  end)

  it('does not suppress real diagnostics', function()
    assert.is_false(perl_parser.is_suppressed_noise('syntax error at perltest.pl line 3, near "= ;"'))
  end)
end)

describe('perl_parser.new_parser', function()
  it('reports a diagnostic and suppresses the trailing summary line', function()
    local parser = perl_parser.new_parser()
    for _, line in ipairs({
      'syntax error at perltest.pl line 3, near "= ;"',
      'Execution of perltest.pl aborted due to compilation errors.',
    }) do
      parser:parse(line)
    end
    local diagnostics = parser:get_result().diagnostics
    assert.are.equal(1, #diagnostics)
    assert.are.equal('perltest.pl', diagnostics[1].filename)
    assert.are.equal('E', diagnostics[1].type)
  end)

  it('reports zero diagnostics for clean output', function()
    local parser = perl_parser.new_parser()
    parser:parse('hi')
    assert.are.same({}, parser:get_result().diagnostics)
  end)
end)
