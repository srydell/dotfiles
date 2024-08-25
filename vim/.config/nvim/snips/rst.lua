return {
  s(
    { trig = 'link', wordTrig = true, dscr = 'A link' },
    fmta(
      [[
        `<> <<<>>>`_
      ]],
      {
        i(1, 'link text'),
        i(2, 'https://google.com'),
      }
    )
  ),
}
