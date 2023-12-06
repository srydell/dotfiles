local helpers = require('srydell.snips.helpers')
local query = require('srydell.treesitter.query')
local util = require('srydell.util')

local get_visual = helpers.get_visual

local function get_surrounding_classname()
  local class = query.get_class_info()
  vim.print(class)
  if class then
    return sn(nil, { i(1, class.name) })
  end
  return sn(nil, { i(1, 'Class') })
end

return {
  postfix('.a', { l('std::atomic<' .. l.POSTFIX_MATCH .. '>') }),

  postfix('.v', { l('std::vector<' .. l.POSTFIX_MATCH .. '>') }),

  s(
    { trig = 'nocopy', wordTrig = true, dscr = 'No copy constructors' },
    fmta(
      [[
        <>(<> &&) = delete;
        <> & operator=(<> &&) = delete;
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        rep(1),
      }
    )
  ),

  s(
    { trig = 'nomove', wordTrig = true, dscr = 'No move constructors' },
    fmta(
      [[
        <>(<> const &) = delete;
        <> & operator=(<> const &) = delete;
      ]],
      {
        d(1, get_surrounding_classname),
        rep(1),
        rep(1),
        rep(1),
      }
    )
  ),

  s(
    { trig = 'str', wordTrig = true, dscr = 'Struct' },
    fmta(
      [[
        struct <>
        {
          <>
        };
      ]],
      {
        i(1, 'Data'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'cls', wordTrig = true, dscr = 'Class' },
    fmta(
      [[
        class <>
        {
          <>
        };
      ]],
      {
        i(1, 'Data'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'ns', wordTrig = true, dscr = 'namespace declaration' },
    fmta(
      [[
        namespace <> {
          <>
        }
      ]],
      {
        i(1, util.get_namespace(util.get_project())),
        i(0),
      }
    )
  ),

  s({ trig = 'pv', wordTrig = true, dscr = 'print something with name log' }, {
    c(1, {
      sn(
        nil,
        fmt(
          [[
                std::cout << "{} = " << {} << '\n';
              ]],
          { rep(1), r(1, 'variable') }
        )
      ),
      sn(
        nil,
        fmta(
          [[
                fmt::print('<> = {}', <>);
              ]],
          { rep(1), r(1, 'variable') }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['variable'] = i(1),
    },
  }),

  s({ trig = 'p', wordTrig = true, dscr = 'print something' }, {
    c(1, {
      sn(
        nil,
        fmt(
          [[
                std::cout << {} << '\n';
              ]],
          { r(1, 'variable') }
        )
      ),
      sn(
        nil,
        fmta(
          [[
                fmt::print('{}', <>);
              ]],
          { r(1, 'variable') }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['variable'] = i(1),
    },
  }),

  s(
    { trig = '^(%s*)i', regTrig = true, dscr = '#include statement' },
    fmta(
      [[
        #include <>
      ]],
      {
        c(1, {
          sn(nil, { t('<'), r(1, 'include'), t('>') }),
          sn(nil, { t('"'), r(1, 'include'), t('"') }),
        }),
      }
    ),
    {
      stored = {
        -- key passed to restoreNodes.
        ['include'] = i(1, 'iostream'),
      },
    }
  ),

  s(
    { trig = 'f', wordTrig = true, dscr = 'Function' },
    fmta(
      [[
        <> <>(<>)
        {
          <>
        }
      ]],
      {
        i(1, 'int'),
        i(2, 'f'),
        i(3),
        i(4),
      }
    )
  ),

  s(
    { trig = 'for', wordTrig = true, dscr = 'for loop' },
    fmta(
      [[
        for (<>) {
          <>
        }
      ]],
      {
        c(1, {
          sn(
            nil,
            fmta( -- Ranged for loop
              [[
                  <> <> : <>
                ]],
              { i(1, 'auto const&'), i(2, 'element'), i(3, 'container') }
            )
          ),
          sn(
            nil,
            fmta( -- Indexed for loop
              [[
                  <> <> = 0; <> << <>; <>++
                ]],
              { i(1, 'int'), i(2, 'i'), rep(2), i(3, 'count'), rep(2) }
            )
          ),
          sn(
            nil,
            fmta( -- Get '\n' terminated strings
              [[
                  std::string <>; std::getline(<>, <>);
                ]],
              { i(1, 'line'), i(2, 'std::cin'), rep(1) }
            )
          ),
          sn(
            nil,
            fmta( -- Iterate over map
              [[
                  <> [<>, <>] : <>
                ]],
              { i(1, 'auto const&'), i(2, 'key'), i(3, 'value'), i(4, 'map') }
            )
          ),
        }),
        i(0),
      }
    )
  ),

  s(
    { trig = 'if', wordTrig = true, dscr = 'if statement' },
    fmta(
      [[
        if (<>) {
          <><>
        }
      ]],
      {
        c(1, {
          sn(
            nil,
            fmta(
              [[
                  <>
                ]],
              { i(1) }
            )
          ),
          sn(
            nil,
            fmta(
              [[
                  std::smatch <>; std::regex_search(<>, <>, <>)
                ]],
              { i(1, 'matches'), i(2, 'string_to_search'), rep(1), i(3, 'pattern') }
            )
          ),
        }),
        d(2, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'tern', wordTrig = true, dscr = 'Ternary operator' },
    fmta(
      [[
        <> ? <> : <>;
      ]],
      {
        i(1),
        i(2),
        i(3),
      }
    )
  ),
}
