-- Python test snippets. This scope is active for Python files under test paths
-- or with *_test.py / *-test.py names. Keep project-agnostic pytest/unittest
-- snippets here instead of in snips/python.lua.

return {
  s(
    { trig = 'test', wordTrig = true, dscr = 'pytest test function' },
    fmta(
      [[
        def test_<>(<>):
            <>
      ]],
      {
        i(1, 'name'),
        i(2),
        i(0),
      }
    )
  ),

  s(
    { trig = 'assert', wordTrig = true, dscr = 'assert statement' },
    fmta(
      [[
        assert <>
      ]],
      {
        i(1, 'actual == expected'),
      }
    )
  ),

  s(
    { trig = 'fixture', wordTrig = true, dscr = 'pytest fixture' },
    fmta(
      [[
        @pytest.fixture
        def <>(<>):
            <>
      ]],
      {
        i(1, 'fixture_name'),
        i(2),
        i(0),
      }
    )
  ),

  s(
    { trig = 'param', wordTrig = true, dscr = 'pytest parametrize' },
    fmta(
      [[
        @pytest.mark.parametrize("<>", [
            <>
        ])
      ]],
      {
        i(1, 'input, expected'),
        i(0, '(input, expected),'),
      }
    )
  ),

  s(
    { trig = 'raises', wordTrig = true, dscr = 'pytest raises block' },
    fmta(
      [[
        with pytest.raises(<>):
            <>
      ]],
      {
        i(1, 'Exception'),
        i(0),
      }
    )
  ),
}
