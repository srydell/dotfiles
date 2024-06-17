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

-- ['./hi.cpp', './dir'] -> ['!hi.cpp', '!dir']
local function trim_relative_add_bang(list)
  for i = 1, #list do
    list[i] = '!' .. string.sub(list[i], 3, -1)
  end
  return list
end

local function skeleton()
  -- Get all files and directories in CWD
  local scan = require('plenary.scandir')
  local cwd = vim.fn.expand('.')
  local directories = trim_relative_add_bang(scan.scan_dir(cwd, { hidden = true, depth = 1, only_dirs = true }))
  local files = trim_relative_add_bang(scan.scan_dir(cwd, { hidden = true, depth = 1, add_dirs = false }))

  return s(
    { trig = 'skeleton', dscr = 'Skeleton snippet' },
    fmta(
      string.format(
        [[
# Ignore everything
/*

# Ignore all files named (wherever they are):
.DS_Store
.log
tags

# Except these
# Files
%s

# Directories
%s
      ]],
        table.concat(files, '\n'),
        table.concat(directories, '\n')
      ),
      {}
    )
  )
end

return {
  snip = skeleton(),
}
