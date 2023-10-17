local ls = require('luasnip')

return {
  ls.snippet(
    { trig='f', dscr='Simple function' },
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
}
