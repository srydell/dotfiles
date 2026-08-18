-- General, language-agnostic helpers for navigating and editing treesitter trees.
local M = {}

M.get_node_text = function(node, buffer)
  buffer = buffer or 0
  return vim.treesitter.get_node_text(node, buffer)
end

M.get_row = function(node)
  local row, _, _, _ = vim.treesitter.get_node_range(node)
  return row
end

-- Go up the treesitter tree until stop condition is met.
-- stop_condition is a function that takes a node and returns
-- false if the search should continue and true if it should stop.
M.search_up_until = function(node, stop_condition)
  if node == nil then
    return
  end

  while node do
    if stop_condition(node) then
      return node
    end

    node = node:parent()
  end
end

-- Go down the treesitter tree from node until stop condition is met.
-- Visit the nodes in breadth first.
-- stop_condition is a function that takes a node and returns
-- false if the search should continue and true if it should stop.
M.search_down_until = function(node, stop_condition)
  if node == nil then
    return
  end

  local nodes = { node }

  while node and not vim.tbl_isempty(nodes) do
    node = table.remove(nodes, 1)

    if stop_condition(node) then
      return node
    end

    for child, _ in node:iter_children() do
      table.insert(nodes, child)
    end
  end
end

-- Parse the buffer content and search down from the root
-- until a stop condition is met or there are no more nodes.
-- stop_condition is a function that takes a node and returns
-- false if the search should continue and true if it should stop.
M.search_down_from_root_until = function(stop_condition, buffer, lang)
  buffer = buffer or 0
  lang = lang or 'cpp'
  local ok, parser = pcall(vim.treesitter.get_parser, buffer, lang)
  if not ok or not parser then
    return
  end

  local trees = parser:parse()
  if not trees then
    return
  end
  for _, tree in ipairs(trees) do
    local root = tree:root()
    if root == nil then
      return
    end

    local end_node = M.search_down_until(tree:root(), stop_condition)
    if end_node then
      return end_node
    end
  end
end

-- Before: `node` sits on the current line, e.g. `int value` with `node` being `value`.
-- After: the line becomes `int std::atomic<value>` for `wrap_node_in('std::atomic<', node, '>')`.
-- The cursor moves right by #before so it stays next to the wrapped text.
M.wrap_node_in = function(before, node, after)
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

-- Before: `node` sits on the current line, e.g. `a += 5;` with `node` being the
-- whole assignment expression.
-- After: the line's `node` text is entirely replaced with `text`, e.g.
-- `a.fetch_add(5, std::memory_order_acq_rel);`.
M.replace_node_with = function(node, text)
  local _, start_node_col, _, end_node_col = vim.treesitter.get_node_range(node)
  local line = vim.api.nvim_get_current_line()

  -- The text that was there before
  -- local to_be_removed = line:sub(start_node_col + 1, end_node_col)

  local new_line = line:sub(1, start_node_col) .. text .. line:sub(end_node_col + 1, -1)

  -- Replace the current line with the wrapped text
  local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
  vim.api.nvim_buf_set_lines(0, row - 1, row, true, { new_line })

  -- Move the cursor the inserted amount. Feels more natural to me.
  -- vim.api.nvim_win_set_cursor(0, { row, col + (text:len() - to_be_removed:len()) })
end

-- Before: `node` ends at some line in the buffer.
-- After: `text` (split on newlines) is inserted as new lines directly below
-- `node`'s end, or `offset` extra lines further down if given. Nothing before
-- or after that insertion point is otherwise touched.
M.add_text_after = function(node, text, offset)
  offset = offset or 0
  local _, _, end_node_row, _ = vim.treesitter.get_node_range(node)

  local lines = {}
  for line in text:gmatch('[^\n]+') do
    table.insert(lines, line)
  end

  -- Replace the current line with the wrapped text
  vim.api.nvim_buf_set_lines(0, end_node_row + 1 + offset, end_node_row + 1 + offset, true, lines)
end

-- A version that reparses the tree
-- Useful when you're trying to act on something that you have not saved yet.
-- Use when not caring about performance
-- `lang` defaults to 'cpp' for the same reason as search_down_from_root_until.
M.get_node_at_cursor = function(winnr, lang)
  winnr = winnr or 0
  lang = lang or 'cpp'
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local cursor_range = { cursor[1] - 1, cursor[2] }

  local buf = vim.api.nvim_win_get_buf(winnr)

  local ok, parser = pcall(vim.treesitter.get_parser, buf, lang)
  if not ok or not parser then
    return nil
  end

  local trees = parser:parse()
  if not trees then
    return nil
  end

  for _, tree in ipairs(trees) do
    local root = tree:root()
    if root then
      return root:named_descendant_for_range(cursor_range[1], cursor_range[2], cursor_range[1], cursor_range[2])
    end
  end

  return nil
end

return M
