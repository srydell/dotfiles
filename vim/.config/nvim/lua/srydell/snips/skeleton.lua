-- Expands filetype-specific skeleton snippets when opening empty files.
-- Load and expand the skeleton module that matches the current filetype.
local function expand_skeleton()
  if vim.bo.ft == '' then
    return
  end

  local module = 'srydell.snips.skeleton.' .. vim.bo.ft
  package.loaded[module] = nil

  local status, skeleton = pcall(require, module)
  if not status then
    local missing_module = string.find(skeleton, "module '" .. module .. "' not found", 1, true)
    if not missing_module then
      error(skeleton)
    end

    print('No skeleton file for ' .. module)
    return
  end

  if not skeleton.snip then
    return
  end

  -- Expand the skeleton snippet into the current buffer.
  require('luasnip').snip_expand(skeleton.snip)
end

-- Autocommands that populate new or externally-created empty files.
local nvim_skeleton = vim.api.nvim_create_augroup('nvim-skeleton', { clear = true })
vim.api.nvim_create_autocmd('BufNewFile', {
  pattern = '*',
  group = nvim_skeleton,
  callback = expand_skeleton,
})

vim.api.nvim_create_autocmd('User', {
  pattern = 'NvimSkeletonInit',
  group = nvim_skeleton,
  callback = expand_skeleton,
})

-- If the file is created outside (for example via touch) but opened empty
vim.api.nvim_create_autocmd('BufRead', {
  group = nvim_skeleton,
  pattern = '*',
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
    if #lines == 1 and lines[1] == '' then
      vim.api.nvim_exec_autocmds('User', { pattern = 'NvimSkeletonInit' })
    end
  end,
})
