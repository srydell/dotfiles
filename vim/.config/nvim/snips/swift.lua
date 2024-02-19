return {

  s(
    { trig = '(%a)st', regTrig = true, dscr = 'Stack' },
    fmta(
      [[
        <>Stack {
          <>
        } //: <>
      ]],
      {
        f(function(_, snip)
          return string.upper(snip.captures[1])
        end, {}),
        i(0),
        f(function(_, snip)
          return string.upper(snip.captures[1]) .. 'STACK'
        end, {}),
      }
    )
  ),

  s(
    { trig = 'img', wordTrig = true, dscr = 'Image' },
    fmta(
      [[
        Image(<>)
      ]],
      {
        i(1),
      }
    )
  ),

  s(
    { trig = 'p', wordTrig = true, dscr = 'print statement' },
    fmta(
      [[
        print(<>)
      ]],
      {
        i(1),
      }
    )
  ),

  s(
    { trig = 'do', wordTrig = true, dscr = 'do catch block' },
    fmta(
      [[
        do {
          <>
        } catch {
          <>
        }
      ]],
      {
        i(1),
        i(0),
      }
    )
  ),

  s(
    { trig = 'f', wordTrig = true, dscr = 'function' },
    fmta(
      [[
        func <>(<>) {
          <>
        }
      ]],
      {
        i(1, 'f'),
        i(2),
        i(0),
      }
    )
  ),

  s(
    { trig = 'mark', wordTrig = true, dscr = '// MARK - ' },
    fmta(
      [[
        // MARK: - <>
      ]],
      {
        i(0),
      }
    )
  ),
  s(
    { trig = 'txt', wordTrig = true, dscr = 'Text()' },
    fmta(
      [[
        Text(<>)
      ]],
      {
        i(1),
      }
    )
  ),
  s(
    { trig = 'if', wordTrig = true, dscr = 'If statement' },
    fmta(
      [[
        if <> {
          <>
        }
      ]],
      {
        i(1, 'true'),
        i(0),
      }
    )
  ),
  s(
    { trig = 'str', wordTrig = true, dscr = 'Struct' },
    fmta(
      [[
        struct <>: <> {
          <>
        }
      ]],
      {
        i(1, 'Name'),
        i(2, 'View'),
        i(0),
      }
    )
  ),
}
