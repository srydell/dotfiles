local util = require('srydell.util')
local helpers = require('srydell.snips.helpers')
local get_visual = helpers.get_visual

local function latest_split_by_dot(args)
  local out = args[1][1]
  local split = util.split(out, '%.')
  if #split > 0 then
    -- Get the last one
    return split[#split]
  end
  return out
end

return {
  s(
    { trig = 'while', wordTrig = true, dscr = 'while loop' },
    fmta(
      [[
        while <> do
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

  s({ trig = 'f', wordTrig = true, dscr = 'Function' }, {
    c(1, {
      sn(
        nil,
        fmt(
          [[
            local function {}({})
              {}
            end
          ]],
          { r(1, 'function_name'), i(2), i(3) }
        )
      ),
      sn(
        nil,
        fmt(
          [[
            local {} = function({})
              {}
            end
          ]],
          { r(1, 'function_name'), i(2), i(3) }
        )
      ),
      sn(
        nil,
        fmt(
          [[
            function {}({})
              {}
            end
          ]],
          { r(1, 'function_name'), i(2), i(3) }
        )
      ),
      sn(
        nil,
        fmt(
          [[
            M.{} = function({})
              {}
            end
          ]],
          { r(1, 'function_name'), i(2), i(3) }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['function_name'] = i(1, 'f'),
    },
  }),

  s(
    { trig = 'c', wordTrig = true, dscr = 'conditional node' },
    fmta(
      [==[
        c(1, {
          sn(
            nil,
            fmta(
              [[
                <<>>
              ]],
              {
                r(1, 'include')
              }
            )
          ),
          sn(
            nil,
            fmta(
              [[
                <<>>
              ]],
              {
                r(1, 'include')
              }
            )
          ),
        }),
      ]==],
      {}
    )
  ),

  s({ trig = 'r', wordTrig = true, dscr = 'require block. Either getting the return or not' }, {
    c(1, {
      sn(
        nil,
        fmt(
          [[
            require('{}')
          ]],
          { r(1, 'include') }
        )
      ),
      sn(
        nil,
        fmt(
          [[
            local {} = require('{}')
          ]],
          { f(latest_split_by_dot, { 1 }), r(1, 'include') }
        )
      ),
      sn(
        nil,
        fmt(
          [[
            local has_{}, {} = pcall(require, '{}')
            if not has_{} then
              return
            end
          ]],
          {
            f(latest_split_by_dot, { 1 }),
            f(latest_split_by_dot, { 1 }),
            r(1, 'include'),
            f(latest_split_by_dot, { 1 }),
          }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['include'] = i(1),
    },
  }),

  s(
    { trig = 's', wordTrig = true, dscr = 'A generic snippet' },
    fmta(
      [==[
        s(
          { trig = '<>', wordTrig = true, dscr = '<>' },
          fmta(
            [[
              <>
            ]],
            {
              <>
            }
          )
        ),
      ]==],
      {
        i(1, 'trigger'),
        i(2, 'Some description'),
        i(3, 'Snipped body'),
        i(4, 'i(1),'),
      }
    )
  ),

  s(
    { trig = 'post', wordTrig = true, dscr = 'A postfix snippet' },
    fmta(
      [==[
        postfix({ trig='<>', dscr='<>' },
          { l(<>), }
        ),
      ]==],
      {
        i(1, 'trigger'),
        i(2, 'Description'),
        i(3, 'l.POSTFIX_MATCH'),
      }
    )
  ),

  s(
    { trig = 'if', wordTrig = true, dscr = 'if statement' },
    fmta(
      [[
        if <> then
          <><>
        end
      ]],
      {
        i(1, 'statement'),
        d(2, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'pv', wordTrig = true, dscr = 'print variable' },
    fmt(
      [[
        vim.print('{} = ' .. {})
      ]],
      { rep(1), i(1, 'variable') }
    )
  ),

  s({ trig = 'p', wordTrig = true, dscr = 'print' }, {
    c(1, {
      sn(
        nil,
        fmta(
          [[
            vim.print(<>)
          ]],
          {
            r(1, 'to_print'),
          }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            print(<>)
          ]],
          {
            r(1, 'to_print'),
          }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['to_print'] = i(1),
    },
  }),

  s(
    { trig = 'for', wordTrig = true, dscr = 'for loop' },
    fmta(
      [[
        for <>, <> in ipairs(<>) do
          <><>
        end
      ]],
      {
        i(1, 'key'),
        i(2, 'value'),
        i(3),
        d(4, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'map', wordTrig = true, dscr = 'Setup a keymap' },
    fmta(
      [[
        vim.keymap.set('<>', <>, <>, { silent = true })
      ]],
      {
        i(1, 'n'),
        i(2, 'keys'),
        i(3, 'command'),
      }
    )
  ),

  s(
    { trig = 'augroup', wordTrig = true, dscr = 'Autogroup' },
    fmta(
      [[
        local <> = vim.api.nvim_create_augroup('<>', { clear = false })
      ]],
      {
        rep(1),
        i(1),
      }
    )
  ),

  s(
    { trig = 'aucmd', wordTrig = true, dscr = 'Autocommand' },
    fmta(
      [[
        vim.api.nvim_create_autocmd({ <> }, {
          pattern = '<>',
          group = <>,
          callback = function()
            <>
          end,
        })
      ]],
      {
        i(1, "'BufNewFile'"),
        i(2, '*.hpp'),
        i(3, 'mygroup'),
        i(0),
      }
    )
  ),
}
