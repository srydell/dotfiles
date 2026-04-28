return {
  'L3MON4D3/LuaSnip',
  -- follow latest release.
  version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
  -- install jsregexp (optional!).
  build = 'make install_jsregexp',
  config = function()
    -- NOTE: Keymaps are defined in cmp-nvim since interactions in popup is weird
    local ls = require('luasnip')
    local snippet_path = vim.fn.stdpath('config') .. '/snips/'

    local function clear_snippet_modules()
      -- Snippet files often call helpers from lua/srydell/snips or
      -- lua/srydell/data. Clear those modules before manual reloads so helper
      -- edits take effect without restarting Neovim.
      for module, _ in pairs(package.loaded) do
        if module:match('^srydell%.snips') or module:match('^srydell%.data%.cpp_operators$') then
          package.loaded[module] = nil
        end
      end
    end

    vim.keymap.set('n', '<leader><leader>l', function()
      clear_snippet_modules()

      local reloaded = false
      for _, filetype in ipairs(require('srydell.snips.context').filetypes_for_buffer(0)) do
        local snippet_file = snippet_path .. filetype .. '.lua'
        if vim.uv.fs_stat(snippet_file) then
          require('luasnip.loaders').reload_file(snippet_file)
          reloaded = true
        end
      end

      if not reloaded then
        require('luasnip.loaders.from_lua').lazy_load({ paths = snippet_path })
      end
    end, { desc = 'Reload snippets for current filetype' })

    vim.api.nvim_create_user_command('LuaSnipEdit', function()
      require('luasnip.loaders').edit_snippet_files()
    end, { desc = 'Choose a snippet file to edit' })

    vim.keymap.set('n', '<leader><leader>e', function()
      require('luasnip.loaders').edit_snippet_files()
    end, { desc = 'Edit snippet files' })

    ls.config.set_config({
      -- Update dynamic snippets as you type
      updateevents = { 'TextChanged', 'TextChangedI' },

      -- Enable autotriggered snippets
      enable_autosnippets = true,

      -- Trigger visual selection
      store_selection_keys = '<C-E>',

      -- ft_func controls which snippet scopes are available for expansion and
      -- completion in the current buffer.
      ft_func = function()
        return require('srydell.snips.context').filetypes_for_buffer(0)
      end,

      -- load_ft_func must mirror ft_func so lazy-loaded snippets are loaded for
      -- every scope that can become active in this buffer.
      load_ft_func = function(bufnr)
        return require('srydell.snips.context').filetypes_for_buffer(bufnr)
      end,
    })

    -- Snippet files are loaded on demand based on load_ft_func. See
    -- lua/srydell/snips/context.lua for the dynamic C++ scopes.
    require('luasnip.loaders.from_lua').lazy_load({ paths = snippet_path })

    vim.api.nvim_create_autocmd('ModeChanged', {
      group = vim.api.nvim_create_augroup('UnlinkLuaSnipSnippetOnModeChange', {
        clear = true,
      }),
      pattern = { 's:n', 'i:*' },
      desc = 'Forget the current snippet when leaving the insert mode',
      callback = function(evt)
        -- If we have n active nodes, n - 1 will still remain after a `unlink_current()` call.
        -- We unlink all of them by wrapping the calls in a loop.
        while true do
          if ls.session and ls.session.current_nodes[evt.buf] and not ls.session.jump_active then
            ls.unlink_current()
          else
            break
          end
        end
      end,
    })
  end,
}
