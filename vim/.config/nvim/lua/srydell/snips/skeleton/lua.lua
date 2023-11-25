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

local function get_skeleton_template()
  return s(
    { trig = '_skeleton', wordTrig = true, hidden = true, dscr = 'Skeleton snippet' },
    fmta(
      [==[
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

          local function skeleton()
            <>
          end

          return {
            snip = skeleton()
          }
        ]==],
      {
        i(0),
      }
    )
  )
end

local function get_overseer_template()
  return s(
    { trig = '_skeleton', wordTrig = true, hidden = true, dscr = 'Skeleton snippet' },
    fmta(
      [==[
          return {
            name = '<>',
            builder = function()
              return {
                cmd = { '<>' },
                args = {
                  '<>',
                },
                components = { 'default' },
              }
            end,
          }
        ]==],
      {
        i(1, 'name'),
        i(2, 'echo'),
        i(0),
      }
    )
  )
end

local function get_overseer_component()
  local choices = {}
  for _, value in ipairs({
    {
      'on_init',
      [[-- Called when the task is created
        -- This is a good place to initialize resources, if needed]],
    },
    { 'on_pre_start', [[-- Return false to prevent task from starting]] },
    { 'on_start', [[-- Called when the task is started]] },
    { 'on_reset', [[-- Called when the task is reset to run again]] },
    {
      'on_pre_result',
      [[-- Called when the task is finalizing.
        -- Return a map-like table value here to merge it into the task result.]],
    },
    {
      'on_preprocess_result',
      [[-- Called right before on_result.
        -- Intended for logic that needs to preprocess the result table and update it in-place.]],
      ', result',
    },
    {
      'on_result',
      [[-- Called when a component has results to set.
        -- Usually this is after the command has completed,
        -- but certain types of tasks may wish to set a result while still running.]],
      ', result',
    },
    { 'on_complete', [[-- Called when the task has reached a completed state.]], ', status, result' },
    { 'on_status', [[-- Called when the task status changes]], ', status' },
    { 'on_output', [[-- Called when there is output from the task]], ', data' },
    {
      'on_output_lines',
      [[-- Called when there is output from the task
        -- Usually easier to deal with than using on_output directly.]],
      ', lines',
    },
    { 'on_exit', [[-- Called when the task command has completed]], ', code' },
    {
      'on_dispose',
      [[-- Called when the task is disposed
        -- Will be called IFF on_init was called, and will be called exactly once.
        -- This is a good place to free resources (e.g. timers, files, etc)]],
    },
  }) do
    local function_name = value[1]
    local comment = value[2]
    local extra_params = value[3] or ''
    table.insert(
      choices,
      sn(
        nil,
        fmt(
          string.format(
            [[%s = function(self, task%s)
        %s
        {}
      end,]],
            function_name,
            extra_params,
            comment
          ),
          { i(1) }
        )
      )
    )
  end

  return s(
    { trig = '_skeleton', wordTrig = true, hidden = true, dscr = 'Skeleton snippet' },
    fmta(
      [==[
        return {
          desc = "<>",
          -- Define parameters that can be passed in to the component
          params = {
            -- See :help overseer-params
          },
          -- The params passed in will match the params defined above
          constructor = function(params)
            return {
              <>
            }
          end,
        }
        ]==],
      {
        i(1, 'Include a description of your component'),
        c(2, choices),
      }
    )
  )
end

local function get_srydell_compilers()
  return s(
    { trig = '_skeleton', wordTrig = true, hidden = true, dscr = 'Skeleton snippet' },
    fmta(
      [==[
        local function get_compilers()
          return { { name = '<>', tasks = { '<>' } } }
        end

        return get_compilers()
      ]==],
      {
        i(1, 'To show in status line'),
        i(2, 'Name corresponding to overseer template'),
      }
    )
  )
end

local function skeleton()
  if vim.fn.expand('%:p:h:t') == 'skeleton' then
    return get_skeleton_template()
  end

  local full_path = vim.fn.expand('%:p')
  string.find
  if string.find(full_path, 'lua/overseer/template/srydell') then
    return get_overseer_template()
  end

  if string.find(full_path, 'lua/overseer/component/srydell') then
    return get_overseer_component()
  end

  if string.find(full_path, 'lua/srydell/compiler/filetype') then
    return get_srydell_compilers()
  end

  -- No skeleton for plain lua
  return nil
end

return {
  snip = skeleton(),
}
