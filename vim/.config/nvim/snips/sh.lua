return {
  s(
    { trig = 'p', wordTrig = true, dscr = 'Print statement' },
    fmta(
      [[
        echo <>
      ]],
      {
        i(0),
      }
    )
  ),
  s(
    { trig = 'if', wordTrig = true, dscr = 'If statement' },
    fmta(
      [[
        if [ <> ]; then
          <>
        fi
      ]],
      {
        i(1),
        i(0),
      }
    )
  ),

  s(
    { trig = 'for', wordTrig = true, dscr = 'For loop' },
    fmta(
      [[
      for <>; do
        <>
      done
      ]],
      {
        i(1, 'filename in ./Data/*.txt'),
        i(0),
      }
    )
  ),
}
