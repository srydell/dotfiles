local ls = require('luasnip')
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require('luasnip.util.events')
local ai = require('luasnip.nodes.absolute_indexer')
local extras = require('luasnip.extras')
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local conds = require('luasnip.extras.expand_conditions')
local postfix = require('luasnip.extras.postfix').postfix
local types = require('luasnip.util.types')
local parse = require('luasnip.util.parser').parse_snippet
local ms = ls.multi_snippet
local k = require('luasnip.nodes.key_indexer').new_key

local util = require('srydell.util')
local helpers = require('srydell.snips.helpers')

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
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['function_name'] = i(1, 'f'),
    },
  }),

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
            local status, {} = pcall(require, '{}')
            if not status then
              return
            end
          ]],
          { f(latest_split_by_dot, { 1 }), r(1, 'include') }
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
        s({ trig='<>', wordTrig=true, dscr='<>' },
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
          <>
        end
      ]],
      {
        i(1, 'statement'),
        i(2),
      }
    )
  ),

  s(
    { trig = 'p', wordTrig = true, dscr = 'print' },
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
    { trig = 'for', wordTrig = true, dscr = 'for loop' },
    fmta(
      [[
        for <>, <> in ipairs(<>) do
          <>
        end
      ]],
      {
        i(1, 'key'),
        i(2, 'value'),
        i(3),
        i(4),
      }
    )
  ),

  s(
    { trig = 'map', wordTrig = true, dscr = 'Setup a keymap' },
    fmta(
      [==[
          vim.keymap.set('<>', '<>', '<>')
        ]==],
      {
        i(1, 'n'),
        i(2, 'keys'),
        i(3, 'command'),
      }
    )
  ),
}
