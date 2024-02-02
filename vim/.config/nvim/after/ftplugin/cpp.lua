-- local includes_query = vim.treesitter.query.get('cpp', 'includes')
--
-- local parser = vim.treesitter.get_parser(0, 'cpp')
-- vim.print(getmetatable(parser))
-- local trees = parser:trees()
-- vim.print(getmetatable(trees))

-- for id, node, metadata in includes_query:iter_captures(tree:root(), 0, 0, -1) do
--   local name = includes_query.captures[id] -- name of the capture in the query
--   vim.print(name)
--   -- typically useful info about the node:
--   local type = node:type() -- type of the captured node
--   local row1, col1, row2, col2 = node:range() -- range of the capture
--   -- ... use the info here ...
-- end

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
