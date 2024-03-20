local helpers = require('srydell.snips.helpers')
local get_visual = helpers.get_visual

return {
  s({ trig = '^(%s*)i', regTrig = true, dscr = 'import statement' }, {
    c(1, {
      sn(nil, { t('import '), r(1, 'package') }),
      sn(nil, { t('from '), r(1, 'package'), t(' import '), i(2) }),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['package'] = i(1, 'statistics'),
    },
  }),

  s(
    { trig = 'f', dscr = 'Simple function' },
    fmta(
      [[
          def <>(<>):
              <>
        ]],
      {
        i(1, 'f'),
        i(2),
        i(0),
      }
    )
  ),

  s(
    { trig = 'if', wordTrig = true, dscr = 'if statement' },
    fmta(
      [[
        if <>:
            <><>
      ]],
      {
        c(1, {
          sn(
            nil,
            fmta(
              [[
              <>
            ]],
              { i(1) }
            )
          ),
          sn(
            nil,
            fmta(
              [[
              re.match(<>, <>)
            ]],
              { i(1, 'pattern'), i(2, 'input') }
            )
          ),
        }),
        d(2, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'for', wordTrig = true, dscr = 'for loop' },
    fmta(
      [[
        for <> in <>:
            <>
      ]],
      {
        i(1, 'item'),
        i(2, 'items'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'p', wordTrig = true, dscr = 'print statement' },
    fmta(
      [[
          print(f"<>")
        ]],
      { i(1) }
    )
  ),

  s(
    { trig = 'pv', wordTrig = true, dscr = 'print variable' },
    fmta(
      [[
          print(f"<> = {<>}")
        ]],
      { rep(1), i(1) }
    )
  ),
}
