local get_visual = require('srydell.snips.helpers').get_visual

return {
  s(
    { trig = 'if', wordTrig = true, dscr = 'If statement' },
    fmta(
      [[
        if <>
          <><>
        endif
      ]],
      {
        i(1),
        d(2, get_visual),
        i(0),
      }
    )
  ),
}
