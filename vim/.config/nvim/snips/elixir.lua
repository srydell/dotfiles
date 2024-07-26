local helpers = require('srydell.snips.helpers')
local get_visual = helpers.get_visual

return {
  s(
    { trig = 'str', wordTrig = true, dscr = 'define a struct' },
    fmta(
      [[
        defmodule <> do
          defstruct <>
        end
      ]],
      {
        i(1, 'User'),
        i(2, 'name: "John", age: 27'),
      }
    )
  ),

  s({ trig = 'map', wordTrig = true, dscr = 'map' }, {
    c(1, {
      sn(
        nil,
        fmta(
          [[
            Enum.map(<>, fn <> ->> <> end)
          ]],
          {
            r(1, 'input'),
            r(2, 'arg'),
            r(3, 'body'),
          }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            Stream.map(<>, fn <> ->> <> end)
          ]],
          {
            r(1, 'input'),
            r(2, 'arg'),
            r(3, 'body'),
          }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['input'] = i(1, '[1, 2, 3]'),
      ['arg'] = i(2, 'element'),
      ['body'] = i(3),
    },
  }),

  s({ trig = 'reduce', wordTrig = true, dscr = 'reduce' }, {
    c(1, {
      sn(
        nil,
        fmta(
          [[
            Enum.reduce(<>, <>, fn <>, <> ->> <> end)
          ]],
          {
            r(1, 'input'),
            r(2, 'start_value'),
            r(3, 'arg'),
            r(4, 'result'),
            r(5, 'body'),
          }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            Stream.reduce(<>, <>, fn <>, <> ->> <> end)
          ]],
          {
            r(1, 'input'),
            r(2, 'start_value'),
            r(3, 'arg'),
            r(4, 'result'),
            r(5, 'body'),
          }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['input'] = i(1, '[1, 2, 3]'),
      ['start_value'] = i(2, '0'),
      ['arg'] = i(3, 'element'),
      ['result'] = i(4, 'result'),
      ['body'] = i(5),
    },
  }),

  s({ trig = 'f', wordTrig = true, dscr = 'module function' }, {
    c(1, {
      sn(
        nil,
        fmta(
          [[
                def <>(<>) do
                  <>
                end
              ]],
          {
            r(1, 'function_name'),
            r(2, 'args'),
            i(0),
          }
        )
      ),
      sn(
        nil,
        fmta(
          [[
                defp <>(<>) do
                  <>
                end
              ]],
          {
            r(1, 'function_name'),
            r(2, 'args'),
            i(0),
          }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['function_name'] = i(1, 'f'),
      ['args'] = i(2),
    },
  }),

  s(
    { trig = 'f', wordTrig = true, dscr = 'function' },
    fmta(
      [[
        def<> <>(<>) do
          <>
        end
      ]],
      {
        i(1),
        i(2, 'f'),
        i(3),
        i(0),
      }
    )
  ),

  s(
    { trig = 'mod', wordTrig = true, dscr = 'Module' },
    fmta(
      [[
        defmodule <> do
          <>
        end
      ]],
      {
        i(1, 'Module'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'fn', wordTrig = true, dscr = 'anonymous function' },
    fmta(
      [[
        fn <> ->> <> end
      ]],
      {
        i(1, 'arg_list'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'cond', wordTrig = true, dscr = 'cond flow statement' },
    fmta(
      [[
        cond do
          <> ->>
            <><>
        end
      ]],
      {
        i(1, '1 == 1'),
        d(2, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'if', wordTrig = true, dscr = 'If statement' },
    fmta(
      [[
        if <> do
          <><>
        end
      ]],
      {
        i(1, 'true'),
        d(2, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'case', wordTrig = true, dscr = 'case flow structure' },
    fmta(
      [[
        case <> do
          <> ->>
            <>
          _ ->>
            <>
        end
      ]],
      {
        i(1, 'to_match_against'),
        i(2, 'value'),
        i(3, '# do_if_matches'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'p', wordTrig = true, dscr = 'print statement' },
    fmta(
      [[
        IO.puts(<>)
      ]],
      {
        c(1, {
          sn(
            nil,
            fmta(
              [[
                <>
              ]],
              { r(1, 'text') }
            )
          ),
          sn(
            nil,
            fmta(
              [[
                "<>"
              ]],
              { r(1, 'text') }
            )
          ),
        }),
      }
    ),
    {
      stored = {
        -- key passed to restoreNodes.
        ['text'] = i(1),
      },
    }
  ),
}
