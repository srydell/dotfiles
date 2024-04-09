local helpers = require('srydell.snips.helpers')

local get_visual = helpers.get_visual

return {
  s(
    { trig = 'for', wordTrig = true, dscr = 'Some description' },
    fmta(
      [[
        {{- range $index, $<> := <> }}
        <>
        {{- end }}
      ]],
      {
        i(1, 'element'),
        i(2, '.Values.myList'),
        d(3, get_visual),
      }
    )
  ),
  s(
    { trig = 'if', wordTrig = true, dscr = 'If statement' },
    fmta(
      [[
        {{- if <> }}
        <>
        {{- end }}
      ]],
      {
        i(1),
        d(2, get_visual),
      }
    )
  ),
}
