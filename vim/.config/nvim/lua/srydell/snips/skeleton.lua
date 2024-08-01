local function expand_skeleton()
  local status, skeleton = pcall(require, 'srydell.snips.skeleton.' .. vim.bo.ft)
  if not status then
    print('No skeleton file for srydell.snips.skeleton.' .. vim.bo.ft)
    return
  end

  if not skeleton.snip then
    print('Skeleton file found but no snippet named "snip" returned.')
    return
  end

  -- Expand the skeleton snippet
  require('luasnip').snip_expand(skeleton.snip)
end

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
