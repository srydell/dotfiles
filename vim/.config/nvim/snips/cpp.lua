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
    fmta(
      [[
        make_completion_token<<result_t<<<>>>>>(<>, <>,
          [<>](result_t<<<>>> <>) mutable {
            <>
          }
        )
      ]],
      {
        i(1, 'void'),
        i(2, 'ExecutorContext::Out'),
        i(3, 'm_executor'),
        i(4),
        i(5),
        rep(1),
        i(0),
      }
    )
  ),

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

  s({ trig = 'require', wordTrig = true, dscr = 'Boost require' }, {
    c(1, {
      sn(
        nil,
        fmta(
          [[
            BOOST_REQUIRE(<>);
          ]],
          { r(1, 'comparison') }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            BOOST_REQUIRE_EQUAL(<>, <>);
          ]],
          { r(1, 'comparison'), r(2, 'other') }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            BOOST_REQUIRE_GE(<>, <>);
          ]],
          { r(1, 'comparison'), r(2, 'other') }
        )
      ),
      sn(
        nil,
        fmta(
          [[
            BOOST_REQUIRE_LE(<>, <>);
          ]],
          { r(1, 'comparison'), r(2, 'other') }
        )
      ),
    }),
  }, {
    stored = {
      -- key passed to restoreNodes.
      ['comparison'] = i(1, 'true'),
      ['other'] = i(2),
    },
  }),

  s(
    { trig = 'test', wordTrig = true, dscr = 'Test case' },
    fmta(
      [[
        BOOST_AUTO_TEST_CASE(<>)
        {
          <>
        }
      ]],
      {
        i(1, 'name_of_the_test'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'svec', wordTrig = true, dscr = 'Stringify vector' },
    fmta(
      [[
        template <<typename T>> string str(vector<<T>> const &v) {
          std::stringstream ss;
          ss <<<< '[';
          for (int i = 0; i << static_cast<<int>>(v.size()); i++) {
            ss <<<< v[i];
            if (i << v.size() - 1) {
              ss <<<< ", ";
            }
          }
          ss <<<< ']';
          return ss.str();
        }
      ]],
      {}
    )
  ),

  s(
    { trig = 'snode', wordTrig = true, dscr = 'Stringify ListNode' },
    fmta(
      [[
        string str(ListNode const *head) {
          std::stringstream ss;
          ss <<<< '[';

          while (head) {
            ss <<<< head->>val;
            if (head->>next) {
              ss <<<< ", ";
            }
            head = head->>next;
          }

          ss <<<< ']';
          return ss.str();
        }
      ]],
      {}
    )
  ),

  s(
    { trig = 'cnode', wordTrig = true, dscr = 'Create ListNode' },
    fmta(
      [[
        ListNode *create(vector<<int>> const &v) {
          ListNode *head = new ListNode();
          ListNode *current = head;
          for (int i = 0; i << static_cast<<int>>(v.size()); i++) {
            current->>val = v[i];
            if (i != v.size() - 1) {
              current->>next = new ListNode();
            }
            current = current->>next;
          }
          return head;
        }
      ]],
      {}
    )
  ),

  s(
    { trig = 'treenode', wordTrig = true, dscr = 'Leetcode TreeNode helpers' },
    fmta(
      [[
        struct TreeNode {
          int val;
          TreeNode *left;
          TreeNode *right;
          TreeNode() : val(0), left(nullptr), right(nullptr) {}
          TreeNode(int x) : val(x), left(nullptr), right(nullptr) {}
          TreeNode(int x, TreeNode *left, TreeNode *right)
              : val(x), left(left), right(right) {}
        };

        std::string str(TreeNode const *root) {
          std::stringstream ss;
          ss <<<< '[';
          if (!root) {
            ss <<<< ']';
            return ss.str();
          }

          std::queue<<TreeNode const *>> nodes;
          nodes.push(root);
          while (!nodes.empty()) {
            auto current = nodes.front();
            nodes.pop();

            ss <<<< current->>val <<<< ", ";
            if (current->>left) {
              nodes.push(current->>left);
            } else {
              ss <<<< "null, ";
            }

            if (current->>right) {
              nodes.push(current->>right);
            } else {
              ss <<<< "null, ";
            }
          }
          string out = ss.str();
          if (out.back() == ' ') {
            // Remove ", "
            out.pop_back();
            out.pop_back();
          }

          out.push_back(']');
          return out;
        }

        TreeNode *create(vector<<optional<<int>>>> const &v) {
          if (v.empty() || !v[0].has_value()) {
            return nullptr;
          }
          TreeNode *root = new TreeNode(v[0].value());
          std::queue<<TreeNode *>> nodes;
          nodes.push(root);
          size_t i = 1;
          while (i << v.size()) {
            TreeNode *current = nodes.front();
            nodes.pop();
            if (i << v.size()) {
              if (v[i]) {
                current->>left = new TreeNode(v[i].value());
                nodes.push(current->>left);
              }
              i++;
            }
            if (i << v.size()) {
              if (v[i]) {
                current->>right = new TreeNode(v[i].value());
                nodes.push(current->>right);
              }
              i++;
            }
          }
          return root;
        }
      ]],
      {}
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
