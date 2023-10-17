return {
  s({ trig='^(%s*)i', regTrig=true, dscr='A generic snippet' },
    fmta(
      [[
        #include <>
      ]],
      {
        c(1, {
          sn(nil, { t('<'), i(1, 'iostream'), t('>') }),
          sn(nil, { t('"'), i(1, 'iostream'), t('"') }),
        }),
      })
  ),

  s(
    { trig='^(%s*)f', regTrig=true, dscr='Function' },
    fmta(
          [[
          <> <>(<>)
          {
            <>
          }
          ]],
          {
            i(1, 'int'),
            i(2, 'f'),
            i(3),
            i(4),
          }
      )
  ),
}
