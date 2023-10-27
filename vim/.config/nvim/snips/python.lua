local helpers = require('snips_helpers')
local get_visual = helpers.get_visual

return {
  s({ trig='_skeleton', wordTrig=true, hidden=true, dscr='Skeleton snippet' },
    fmta(
      [[
        def main():
          <>

        if __name__ == '__main__':
          main()
      ]],
      { i(0) }
    )
  ),

  s({ trig='f', dscr='Simple function' },
    fmta(
        [[
          def <>(<>):
        ]],
        {
          i(1, 'f'),
          i(2),
        }
      )
  ),

  s({ trig='if', wordTrig=true, dscr='if statement' },
      {
        c(1, {
          sn(nil, fmta(
            [[
              if <>:
                <>
            ]], { i(1), d(2, get_visual) })),
          sn(nil, fmta(
            [[
              if re.match(<>, <>)
                <>
            ]], { i(1, 'pattern'), i(2, 'input'), d(3, get_visual) })),
        }),
      }
  ),

  s({ trig='p', wordTrig=true, dscr='print statement' },
      fmta(
        [[
          print(f"<>")
        ]],
        { i(1) }
      )
  ),

  s({ trig='pv', wordTrig=true, dscr='print variable' },
      fmta(
        [[
          print(f"<> = {<>}")
        ]],
        { rep(1), i(1) }
      )
  ),

}
