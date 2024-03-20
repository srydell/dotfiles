local helpers = require('srydell.snips.helpers')

local get_visual = helpers.get_visual

return {

  s(
    { trig = 'link', wordTrig = true, dscr = 'NavigationLink' },
    fmta(
      [[
        NavigationLink {
          <>
        } label: {
          <>
        }
      ]],
      {
        i(1),
        d(2, get_visual),
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
    { trig = 'link', wordTrig = true, dscr = 'Link' },
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
