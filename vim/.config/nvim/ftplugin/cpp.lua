local function get_node_text(node)
  return vim.treesitter.get_node_text(node, 0)
end

-- Wrap a treesitter node on the current line in text as
-- node_text -> before .. node_text .. after
-- This assumes that the node is on the current line of the cursor
local function wrap_node_in(node, before, after)
  local _, start_node_col, _, end_node_col = vim.treesitter.get_node_range(node)
  local line = vim.api.nvim_get_current_line()

  -- The text that was there before
  local to_be_wrapped = line:sub(start_node_col + 1, end_node_col)

  local new_line = line:sub(1, start_node_col) .. before .. to_be_wrapped .. after .. line:sub(end_node_col + 1, -1)

  -- Replace the current line with the wrapped text
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row - 1, row, true, { new_line })

  -- Move the cursor the inserted amount. Feels more natural to me.
  vim.api.nvim_win_set_cursor(0, { row, col + before:len() })
end

local function replace_node_with(node, text)
  local _, start_node_col, _, end_node_col = vim.treesitter.get_node_range(node)
  local line = vim.api.nvim_get_current_line()

  -- The text that was there before
  local to_be_removed = line:sub(start_node_col + 1, end_node_col)

  local new_line = line:sub(1, start_node_col) .. text .. line:sub(end_node_col + 1, -1)

  -- Replace the current line with the wrapped text
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row - 1, row, true, { new_line })

  -- Move the cursor the inserted amount. Feels more natural to me.
  -- vim.api.nvim_win_set_cursor(0, { row, col + (text:len() - to_be_removed:len()) })
end

-- variable = 54 -> variable.store(54, std::memory_order_release)
local function make_atomic_store()
  local ts_utils = require('nvim-treesitter.ts_utils')

  local function is_assignment(node)
    return node:type() == 'assignment_expression'
  end

  local function is_increment(node)
    -- E.g. ++ or --
    return node:type() == 'update_expression'
  end

  local curr_node = ts_utils.get_node_at_cursor()
  while curr_node do
    if is_assignment(curr_node) then
      -- E.g. a += 5;
      local assignment = {}
      for child, name in curr_node:iter_children() do
        assignment[name] = child
      end

      -- Early exit
      if assignment.left == nil or assignment.operator == nil or assignment.right == nil then
        return
      end

      local operator = get_node_text(assignment.operator)
      local left = get_node_text(assignment.left)
      local right = get_node_text(assignment.right)
      if operator == '=' then
        replace_node_with(curr_node, left .. '.store(' .. right .. ', std::memory_order_release)')
      elseif operator == '+=' then
        replace_node_with(curr_node, left .. '.fetch_add(' .. right .. ', std::memory_order_acq_rel)')
      elseif operator == '-=' then
        replace_node_with(curr_node, left .. '.fetch_sub(' .. right .. ', std::memory_order_acq_rel)')
      end

      return
    elseif is_increment(curr_node) then
      -- E.g. a++;
      local increment = {}
      for child, name in curr_node:iter_children() do
        increment[name] = child
      end
      if increment.argument == nil or increment.operator == nil then
        return
      end

      local argument = get_node_text(increment.argument)
      local operator = get_node_text(increment.operator)
      if operator == '++' then
        replace_node_with(curr_node, argument .. '.fetch_add(1, std::memory_order_acq_rel)')
      elseif operator == '--' then
        replace_node_with(curr_node, argument .. '.fetch_sub(1, std::memory_order_acq_rel)')
      end

      return
    end

    -- Go up in the stack
    curr_node = curr_node:parent()
  end
end

-- variable -> variable.load(std::memory_order_acquire)
local function make_atomic_load()
  local ts_utils = require('nvim-treesitter.ts_utils')

  local function is_variable(node)
    return node:type() == 'identifier'
  end

  local curr_node = ts_utils.get_node_at_cursor()
  while curr_node do
    if is_variable(curr_node) then
      wrap_node_in(curr_node, '', '.load(std::memory_order_acquire)')
      return
    end

    -- Go up in the stack
    curr_node = curr_node:parent()
  end
end

-- Make the type under the cursor atomic. I.e.
-- int -> std::atomic<int>
-- If the node under the cursor is not a type, do nothing
local function make_atomic()
  local ts_utils = require('nvim-treesitter.ts_utils')

  local function is_type(node)
    return node:type() == 'primitive_type' or node:type() == 'type_identifier'
  end

  local curr_node = ts_utils.get_node_at_cursor()
  while curr_node do
    if is_type(curr_node) then
      wrap_node_in(curr_node, 'std::atomic<', '>')
      return
    end

    -- Go up in the stack
    curr_node = curr_node:parent()
  end
end

vim.keymap.set('n', '<leader>ral', make_atomic_load)
vim.keymap.set('n', '<leader>ras', make_atomic_store)
vim.keymap.set('n', '<leader>raa', make_atomic)
