return {
  s(
    { trig = 'p', wordTrig = true, dscr = 'Print' },
    fmta(
      [[
        message(STATUS "<>")
      ]],
      {
        i(1),
      }
    )
  ),

  s(
    { trig = 'pv', wordTrig = true, dscr = 'Print' },
    fmta(
      [[
        message(FATAL_ERROR "<> = ${<>}")
      ]],
      {
        i(1),
        rep(1),
      }
    )
  ),
}
