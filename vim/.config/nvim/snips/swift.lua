local helpers = require('srydell.snips.helpers')

local get_visual = helpers.get_visual

return {

  s(
    { trig = 'enum', wordTrig = true, dscr = 'enum' },
    fmta(
      [[
        enum <> {
          case <>
        }
      ]],
      {
        i(1, 'EnumName'),
        i(0, 'firstCase'),
      }
    )
  ),

  s(
    { trig = 'switch', wordTrig = true, dscr = 'switch enum' },
    fmta(
      [[
        switch <> {
        case <>:
          <>
        }
      ]],
      {
        i(1, 'enumVariable'),
        i(2, 'firstCase'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'linknav', wordTrig = true, dscr = 'NavigationLink' },
    fmta(
      [[
        NavigationLink {
          <>
        } label: {
          <><>
        }
      ]],
      {
        i(1),
        d(2, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'i', wordTrig = true, dscr = 'import statement' },
    fmta(
      [[
        import <>
      ]],
      {
        i(1, 'SwiftUI'),
      }
    )
  ),

  s(
    { trig = 'appstorage', wordTrig = true, dscr = '@AppStorage variable' },
    fmta(
      [[
        @AppStorage("<>") var <>: <>
      ]],
      {
        rep(1),
        i(1, 'variableName'),
        i(2, 'Bool = false'),
      }
    )
  ),

  s(
    { trig = 'state', wordTrig = true, dscr = '@State variable' },
    fmta(
      [[
        @State private var <>: <>
      ]],
      {
        i(1, 'variableName'),
        i(2, 'Bool = false'),
      }
    )
  ),

  s(
    { trig = 'linkurl', wordTrig = true, dscr = 'Link' },
    fmta(
      [[
        Link("<>", destination: URL(string: <>)!)
      ]],
      {
        i(1, 'Wikipedia'),
        i(2, '"https://wikipedia.com"'),
      }
    )
  ),

  s(
    { trig = 'binding', wordTrig = true, dscr = '@Binding variable' },
    fmta(
      [[
        @Binding var <>: <>
      ]],
      {
        i(1, 'variableName'),
        i(2, 'Bool'),
      }
    )
  ),

  s(
    { trig = 'btn', wordTrig = true, dscr = 'Basic button' },
    fmta(
      [[
        Button(action: {
          <>
        }) {
          <>
        }
      ]],
      {
        i(1),
        i(2),
      }
    )
  ),

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
        d(1, get_visual),
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
    { trig = 'foreach', wordTrig = true, dscr = 'ForEach' },
    fmta(
      [[
        ForEach(<>) { <> in
          <>
        }
      ]],
      {
        i(1, 'items'),
        i(2, 'item'),
        i(0),
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
          <><>
        }
      ]],
      {
        i(1, 'true'),
        d(2, get_visual),
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
