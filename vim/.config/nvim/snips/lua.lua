return {

  s(
    { trig='^(%s*)s', regTrig=true, dscr='A generic snippet' },
    fmta(
        [==[
          s(
            { trig='^(%s*)<>', regTrig=true, dscr='<>' },
            fmta(
                  [[
                  <>
                  ]],
                  {
                    <>
                  }
              )
          ),
        ]==],
        {
          i(1, 'trigger'),
          i(2, 'Some description'),
          i(3, 'Snipped body'),
          i(4, 'i(1),'),
        }
      )
    ),
  s(
    { trig='^(%s*)if', regTrig=true, dscr='if statement' },
    fmta(
          [[
          if <> then
            <>
          end
          ]],
          {
            i(1, 'statement'),
            i(2),
          }
      )
  ),
  s(
    { trig='^(%s*)map', regTrig=true,  dscr='Setup a keymap' },
    fmta(
        [==[
          vim.keymap.set('<>', '<>', '<>')
        ]==],
        {
          i(1, 'n'),
          i(2, 'keys'),
          i(3, 'command'),
        }
      )
    ),
}
