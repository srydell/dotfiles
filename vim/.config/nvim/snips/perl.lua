return {
  s(
    { trig = 'f', wordTrig = true, dscr = 'Function' },
    fmta(
      [[
        sub <> {
            <>
        }
      ]],
      {
        i(1, 'function_name'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'if', wordTrig = true, dscr = 'if statement' },
    fmta(
      [[
        if (<>) {
            <>
        }
      ]],
      {
        i(1, '1'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'p', wordTrig = true, dscr = 'print statement' },
    fmta(
      [[
        print "<>\n"
      ]],
      {
        i(1),
      }
    )
  ),
}
