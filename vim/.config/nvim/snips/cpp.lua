local helpers = require('srydell.snips.helpers')
local query = require('srydell.treesitter.query')
local util = require('srydell.util')

local get_visual = helpers.get_visual

local function get_surrounding_classname()
  local class = query.get_class_info()
  if class then
    return sn(nil, { i(1, class.name) })
  end
  return sn(nil, { i(1, 'Class') })
end

-- In a header file -> ';'
-- In a source file -> ' {\n<indent>\n}'
local function get_definition_or_declaration()
  local extension = vim.fn.expand('%:e')
  if extension == 'h' or extension == 'hpp' then
    return sn(nil, { t(';') })
  end
  return sn(
    nil,
    fmta(' ' .. [[
        {
          <>
        }
      ]], {
      i(1),
    })
  )
end

return {
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
        i(1),
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
        d(3, get_definition_or_declaration),
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
        d(3, get_definition_or_declaration),
      }
    )
  ),

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
          <>
        }
      ]],
      {
        i(1, 'true'),
        i(0),
      }
    )
  ),

  s(
    { trig = 'f', wordTrig = true, dscr = 'Function' },
    fmta(
      [[
        <> <>(<>)<>
      ]],
      {
        i(1, 'int'),
        i(2, 'f'),
        i(3),
        d(4, get_definition_or_declaration),
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
              { i(1, 'size_t'), i(2, 'i'), rep(2), i(3, 'count'), rep(2) }
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
    { trig = 'svec', wordTrig = true, dscr = 'Stringify vector' },
    fmta(
      [[
        template <<typename T>> string str(vector<<T>> const &v) {
          std::stringstream ss;
          ss <<<< '[';
          for (size_t i = 0; i << v.size(); i++) {
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
          for (size_t i = 0; i << v.size(); i++) {
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
}
