local helpers = require('srydell.snips.helpers')

local get_visual = helpers.get_visual

return {
  s(
    { trig = 'div', wordTrig = true, dscr = 'div' },
    fmta(
      [[
      <<div class="<>">>
        <><>
      <</div>>
      ]],
      {
        i(1),
        d(2, get_visual),
        i(0),
      }
    )
  ),
}
