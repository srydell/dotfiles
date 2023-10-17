local ls = require('luasnip')

return {

  ls.snippet(
    { trig='^(%s*)s', regTrig=true, dscr='A generic snippet' },
    fmta(
        [==[
          ls.snippet(
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
  ls.snippet(
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
  ls.snippet(
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
