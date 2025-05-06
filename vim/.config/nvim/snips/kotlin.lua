return {
  s(
    { trig = 'p', wordTrig = true, dscr = 'Print statement' },
    fmta(
      [[
        println("<>")
      ]],
      {
        i(1),
      }
    )
  ),
  s(
    { trig = 'f', wordTrig = true, dscr = 'A function' },
    fmta(
      [[
        fun <>(<>) {
          <>
        }
      ]],
      {
        i(1),
        i(2),
        i(0),
      }
    )
  ),
  s(
    { trig = 'cls', wordTrig = true, dscr = 'Class' },
    fmta(
      [[
        class <>(<>) {
          <>
        }
      ]],
      {
        i(1, 'ClassName'),
        i(2),
        i(0),
      }
    )
  ),
  s(
    { trig = 'while', wordTrig = true, dscr = 'While statement' },
    fmta(
      [[
        while (<>) {
          <>
        }
      ]],
      {
        i(1, 'true'),
        i(0),
      }
    )
  ),
  s(
    { trig = 'for', wordTrig = true, dscr = 'For statement' },
    fmta(
      [[
        for (<> in <>) {
          <>
        }
      ]],
      {
        i(1, 'number'),
        i(2, '1..5'),
        i(0),
      }
    )
  ),
  s(
    { trig = 'tern', wordTrig = true, dscr = 'Ternary expression' },
    fmta(
      [[
        if (<>) <> else <>
      ]],
      {
        i(1, 'true'),
        i(2, '"Truthy"'),
        i(3, '"Falsy"'),
      }
    )
  ),
  s(
    { trig = 'if', wordTrig = true, dscr = 'If statement' },
    fmta(
      [[
        if (<>) {
          <>
        }
      ]],
      {
        i(1),
        i(0),
      }
    )
  ),
}
