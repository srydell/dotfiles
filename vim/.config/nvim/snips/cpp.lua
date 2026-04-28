local util = require('srydell.util')
local cpp_snips = require('srydell.snips.cpp')
local get_visual = require('srydell.snips.helpers').get_visual

local ls = require('luasnip')
local fmta = require('luasnip.extras.fmt').fmta
local sn = ls.snippet_node
local i = ls.insert_node
local t = ls.text_node

local function guess_class_name()
  -- Without extension
  -- src/hello.cpp -> hello
  local filename = vim.fn.expand('%:t:r')
  -- hello -> Hello
  local class_name = filename:sub(1, 1):upper() .. filename:sub(2)
  return sn(nil, { i(1, class_name) })
end

local function get_surrounding_classname()
  local class = require('srydell.treesitter.cpp').get_class_name_under_cursor()
  if class then
    return sn(nil, { t(class) })
  end
  return sn(nil, { i(1, 'Class') })
end

return {
  s(
    { trig = 'operator(%W+)', trigEngine = 'pattern', dscr = 'operator expansion' },
    fmta(
      [[
        <>
      ]],
      {
        d(1, cpp_snips.get_operator),
      }
    )
  ),
  s(
    { trig = 'switch', wordTrig = true, dscr = 'switch statement' },
    fmta(
      [[
        switch (<>) {
          <>
        }
      ]],
      {
        i(1),
        d(2, cpp_snips.get_enum_choice_snippet, { 1 }),
      }
    )
  ),

  postfix('.a', { l('std::atomic<' .. l.POSTFIX_MATCH .. '>') }),

  postfix('.v', { l('std::vector<' .. l.POSTFIX_MATCH .. '>') }),

  s(
    { trig = 'try', wordTrig = true, dscr = 'try catch statement' },
    fmta(
      [[
        try {
          <>
        } catch (<>) {
          <>
        }
      ]],
      {
        d(1, get_visual),
        i(2, 'std::exception const & e'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'ctor', wordTrig = true, dscr = 'Create a constructor' },
    fmta(
      [[
        <>(<>)<>
      ]],
      {
        d(1, get_surrounding_classname),
        i(2),
        d(3, cpp_snips.get_definition_or_declaration),
      }
    )
  ),

  s(
    { trig = 'dtor', wordTrig = true, dscr = 'Create a destructor' },
    fmta(
      [[
        ~<>(<>)<>
      ]],
      {
        d(1, get_surrounding_classname),
        i(2),
        d(3, cpp_snips.get_definition_or_declaration),
      }
    )
  ),

  s(
    { trig = 'nocopy', wordTrig = true, dscr = 'No copy constructors' },
    fmta(
      [[
        <>(<> &) = delete;
        <> & operator=(<> &) = delete;
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
        <>(<> const &&) = delete;
        <> & operator=(<> const &&) = delete;
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
          <><>
        };
      ]],
      {
        d(1, guess_class_name),
        d(2, get_visual),
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
          <><>
        };
      ]],
      {
        d(1, guess_class_name),
        d(2, get_visual),
        i(0),
      }
    )
  ),

  s(
    { trig = 'ns', wordTrig = true, dscr = 'namespace declaration' },
    fmta(
      [[
        namespace <> {
          <><>
        }
      ]],
      {
        i(1, util.get_namespace(util.get_project())),
        d(2, get_visual),
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
    { trig = 'while', wordTrig = true, dscr = 'while statement' },
    fmta(
      [[
        while (<>) {
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
    { trig = 'f', wordTrig = true, dscr = 'Function' },
    fmta(
      [[
        <>
      ]],
      {
        d(1, cpp_snips.get_function_snippet),
      }
    ),
    {
      stored = {
        -- key passed to restoreNodes.
        ['function_name'] = i(1, 'f'),
      },
    }
  ),

  s(
    { trig = 'for', wordTrig = true, dscr = 'for loop' },
    fmta(
      [[
        for (<>) {
          <><>
        }
      ]],
      {
        d(1, cpp_snips.get_for_loop_choices_for_snippet),
        d(2, get_visual),
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

  s(
    { trig = 'enum', wordTrig = true, dscr = 'enum class' },
    fmta(
      [[
        enum class <>
        {
          <>
        };
      ]],
      {
        i(1, 'Enum'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'tp', wordTrig = true, dscr = 'Template' },
    fmt(
      [[
        template<typename {}>
      ]],
      {
        i(1, 'T'),
      }
    )
  ),
}
