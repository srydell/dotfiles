local helpers = require('srydell.snips.helpers')
local get_visual = helpers.get_visual

local repeat_capture = function(_, snip)
  return string.rep('#', #snip.captures[1])
end

return {

  s(
    { trig='cbl', wordTrig=true, dscr='Code block' },
    fmta(
      [[
        ```<>
        <>
        ```
      ]], { i(1, 'sh'), d(2, get_visual) })
    ),

  s({trig = "(s+)ec", regTrig = true, dscr = "Section based on how many 's'"},
    fmt(
      [[
          {} {} {}

      ]],
      {
        f(repeat_capture),
        i(1),
        f(repeat_capture),
      }
    )
  ),

}
