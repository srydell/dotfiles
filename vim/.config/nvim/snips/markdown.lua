local helpers = require('srydell.snips.helpers')
local get_visual = helpers.get_visual

local repeat_capture = function(_, snip)
  return string.rep('#', #snip.captures[1])
end

return {
  postfix({ trig='.c', dscr='Inline code' },
    { l('`' .. l.POSTFIX_MATCH .. '`'), }
  ),

  postfix({ trig='.i', dscr='Italic text' },
    { l('*' .. l.POSTFIX_MATCH .. '*'), }
  ),

  postfix({ trig='.b', dscr='Bold text' },
    { l('**' .. l.POSTFIX_MATCH .. '**'), }
  ),

  s({ trig='link', wordTrig=true, dscr='A link' },
    {
      c(1, {
          sn(nil, fmta(
              [[
                [<>](<>)
              ]], { r(1, 'link text'), r(2, 'link') })),
            sn(nil, fmta(
              [[
                [<>](<> "<>")
              ]], { r(1, 'link text'), r(2, 'link'), i(3, 'On hover text') })),
        }
      ),
    },
    {
      stored = {
          -- key passed to restoreNodes.
          ['link text'] = i(1),
          ['link'] = i(2)
      }
    }
  ),


  s({ trig='img', wordTrig=true, dscr='Image' },
    fmta(
      [[
        ![<>](<>)
      ]],
      {
        i(1, 'Image description'),
        i(2, 'path/to/img.png'),
      }
    )
  ),

  s({ trig='cbl', wordTrig=true, dscr='Code block' },
    fmta(
      [[
        ```<>
        <>
        ```
      ]], { i(1, 'sh'), d(2, get_visual) })
    ),

  s({trig = '(s+)ec', regTrig = true, dscr = "Section based on how many 's'"},
    fmt(
      [[
          {} {}

      ]],
      {
        f(repeat_capture),
        i(1),
      }
    )
  ),

}
