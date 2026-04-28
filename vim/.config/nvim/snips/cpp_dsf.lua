local get_visual = require('srydell.snips.helpers').get_visual

local ls = require('luasnip')
local fmta = require('luasnip.extras.fmt').fmta
local sn = ls.snippet_node
local i = ls.insert_node

return {
  s(
    { trig = 'ct', wordTrig = true, dscr = 'CompletionToken' },
    fmta(
      [[
        Completion_token<<result_t<<<>>>>>
      ]],
      {
        i(1, 'void'),
      }
    )
  ),

  s(
    { trig = 'mkct', wordTrig = true, dscr = 'make_completiontoken' },
    fmt(
      [[
        make_completion_token<dsf::result_t<{}>>({}, {},
          [{}](auto {}) mutable {{
            {}
          }}
        )
      ]],
      {
        i(1, 'void'),
        i(2, 'ExecutorContext::Out'),
        i(3, 'm_executor'),
        i(4),
        i(5, 'rc'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'post', wordTrig = true, dscr = 'Post to a context' },
    fmta(
      [[
        post(<>, <>,
          [<>]() mutable {
            <><>
        });
      ]],
      {
        i(1, 'ExecutorContext::Out'),
        i(2, 'm_executor'),
        i(3),
        d(4, get_visual),
        i(0),
      }
    )
  ),

  s({ trig = 'log', wordTrig = true, dscr = 'log something' }, {
    c(1, {
      sn(
        nil,
        fmta(
          [[
            DSF_LOG(oal::log_<>, "<>");
          ]],
          { r(1, 'log_level'), r(2, 'text') }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            DSF_FLOG(oal::log_<>, "<>", <>);
          ]],
          { r(1, 'log_level'), r(2, 'text'), i(3) }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            OAL_LOG(oal::log_<>, "<>");
          ]],
          { r(1, 'log_level'), r(2, 'text') }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['log_level'] = i(1, 'info'),
      ['text'] = i(2),
    },
  }),
}
