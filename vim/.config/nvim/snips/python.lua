local helpers = require('srydell.snips.helpers')
local get_visual = helpers.get_visual

return {

  s(
    { trig = 'ctor', wordTrig = true, dscr = 'Constructor' },
    fmta(
      [[
        def __init__(self<>):
            <>
      ]],
      {
        i(1, ', data'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'str', wordTrig = true, dscr = 'data class' },
    fmta(
      [[
        @dataclass
        class <>:
            <>
      ]],
      {
        i(1, 'Data'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'cls', wordTrig = true, dscr = 'Class' },
    fmta(
      [[
        class <>:
            <>
      ]],
      {
        i(1, 'ClassName'),
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
        i(1, 'thing'),
        i(2, 'things'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'with', wordTrig = true, dscr = 'with open' },
    fmta(
      [[
        with open("<>") as <>:
            <>
      ]],
      {
        i(1, 'filename.txt'),
        i(2, 'f'),
        i(0),
      }
    )
  ),

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

  s({ trig = 'p', wordTrig = true, dscr = 'print statement' }, {
    c(1, {
      sn(
        nil,
        fmta(
          [[
              print(<>)
            ]],
          {
            r(1, 'to_be_printed'),
          }
        )
      ),
      sn(
        nil,
        fmta(
          [[
              print(f"<>")
            ]],
          {
            r(1, 'to_be_printed'),
          }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['to_be_printed'] = i(1),
    },
  }),

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
