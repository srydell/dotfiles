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

local helpers = require('snips_helpers')

return {
  s({ trig='r', wordTrig=true, dscr='require block. Either getting the return or not' },
      {
        c(1, {
          sn(nil, { t("require('"), r(1, 'include'), t("')") }),
          sn(nil, { t("local "), rep(1), t(" = require('"), r(1, 'include'), t("')") }),
        }),
      },
      {
        stored = {
            -- key passed to restoreNodes.
            ['include'] = i(1)
        }
      }
  ),

  s(
    { trig='s', wordTrig=true, dscr='A generic snippet' },
    fmta(
        [==[
          s(
            { trig='<>', wordTrig=true, dscr='<>' },
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
    { trig='if', wordTrig=true, dscr='if statement' },
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
    { trig='map', wordTrig=true,  dscr='Setup a keymap' },
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
