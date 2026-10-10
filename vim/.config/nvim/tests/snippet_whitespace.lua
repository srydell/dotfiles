-- Run from nvim: nvim --headless -u NONE -l tests/snippet_whitespace.lua
vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/lazy/LuaSnip')
local ls = require('luasnip')

-- Formatting checks use predictable context rather than a parser installation.
local enum
package.loaded['srydell.treesitter.cpp'] = {
  get_class_name_under_cursor = function()
    return 'Widget'
  end,
  get_surrounding_argument_list = function() end,
  get_surrounding_function = function() end,
  find_enum_from_type = function()
    return enum
  end,
}

local function load_snippets(file)
  local chunk = assert(loadfile('snips/' .. file .. '.lua'))
  setfenv(
    chunk,
    setmetatable({}, {
      __index = function(_, key)
        return ls.session.get_snip_env()[key] or _G[key]
      end,
    })
  )
  local result = {}
  for _, snippet in ipairs(chunk()) do
    result[snippet.trigger] = snippet
  end
  return result
end

local cpp = load_snippets('cpp')
local dsf = load_snippets('cpp_dsf')
local test = load_snippets('cpp_test')
local lua = load_snippets('lua')
local python = load_snippets('python')

local function check(snippet, indent, expected, selection)
  vim.cmd('enew!')
  vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. '/widget.cpp')
  vim.bo.expandtab, vim.bo.shiftwidth, vim.bo.tabstop = true, 2, 2
  vim.api.nvim_set_current_line(indent)
  ls.snip_expand(snippet, {
    pos = { 0, #indent },
    expand_params = {
      env_override = selection and {
        LS_SELECT_DEDENT = selection,
        LS_SELECT_RAW = vim.tbl_map(function(line)
          return '    ' .. line
        end, selection),
      } or nil,
    },
  })
  local actual = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(vim.deep_equal(actual, expected), vim.inspect({ actual = actual, expected = expected }))
end

check(cpp.ctor, '', { 'Widget() {', '  ', '}' })
check(cpp.dtor, '  ', { '  ~Widget() {', '    ', '  }' })
check(cpp.f, '  ', { '  void f() {', '    ', '  }' })
check(cpp.switch, '', { 'switch () {', '  case 0: {', '    return;', '  }', '}' })
enum = { name = 'Color', values = { 'red', 'blue' } }
check(cpp.switch, '  ', {
  '  switch () {',
  '    case Color::red: {',
  '      return;',
  '    }',
  '    case Color::blue: {',
  '      return;',
  '    }',
  '  }',
})
check(cpp['if'], '  ', {
  '  if () {',
  '    first();',
  '    if (ready) {',
  '      second();',
  '    }',
  '  }',
}, { 'first();', 'if (ready) {', '  second();', '}' })
check(cpp.str, '', { 'struct Widget', '{', '  first();', '  second();', '};' }, { 'first();', 'second();' })
check(cpp['while'], '', { 'while (true) {', '  ', '}' })
check(cpp.try, '', { 'try {', '  ', '} catch (std::exception const & e) {', '  ', '}' })
check(cpp['^(%s*)i'], '', { '#include <iostream>' })
check(test.test, '  ', { '  BOOST_AUTO_TEST_CASE(name_of_the_test)', '  {', '    ', '  }' })
check(dsf.post, '  ', {
  '  post(ExecutorContext::Out, m_executor,',
  '    []() mutable {',
  '      first();',
  '      second();',
  '    });',
}, { 'first();', 'second();' })
check(lua['while'], '  ', { '  while true do', '    ', '  end' })
check(lua.f, '', { 'local function f()', '  ', 'end' })
check(lua['if'], '  ', { '  if statement then', '    first()', '    second()', '  end' }, { 'first()', 'second()' })
check(python['if'], '    ', { '    if :', '        first()', '        second()' }, { 'first()', 'second()' })
vim.cmd('qa!')
