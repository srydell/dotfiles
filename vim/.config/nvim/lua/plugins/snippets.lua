return
{
	'L3MON4D3/LuaSnip',
	-- follow latest release.
	version = 'v2.*', -- Replace <CurrentMajor> by the latest released major (first number of latest release)
	-- install jsregexp (optional!).
	build = 'make install_jsregexp',
  config = function ()
		-- NOTE: Keymaps are defined in cmp-nvim since interactions in popup is weird
		local ls = require('luasnip')
		require('luasnip.loaders.from_lua').load({paths = '~/.config/nvim/luasnip/'})
		ls.config.set_config({
			-- Enable autotriggered snippets
			enable_autosnippets = true,

			-- Use Tab (or some other key if you prefer) to trigger visual selection
			store_selection_keys = '<C-E>',
		})
end
}
