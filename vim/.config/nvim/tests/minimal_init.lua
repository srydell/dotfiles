-- Minimal init.lua for running the plenary.nvim busted specs under tests/
-- headlessly, without booting the full lazy.nvim plugin setup.
--
-- Run from the nvim config root (vim/.config/nvim):
--   nvim --headless -u NONE -c "lua \
--     vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/lazy/plenary.nvim'); \
--     vim.opt.runtimepath:append(vim.fn.getcwd()); \
--     require('plenary.test_harness').test_directory('tests/', { minimal_init = 'tests/minimal_init.lua' })" \
--     -c 'qa'
-- (PlenaryBustedFile/-Directory's `-u`-based ex commands don't reliably
-- forward this minimal_init to the child process they spawn, so the direct
-- Lua API call above is the dependable way to run these headlessly.)

-- plenary.nvim is already installed as a transitive dependency of other
-- plugins (harpoon, telescope, ...), so reuse the copy lazy.nvim manages
-- instead of adding a new one.
vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/lazy/plenary.nvim')

-- overseer.nvim itself is a real lazy.nvim plugin (not vendored here); its
-- `overseer.parselib`/`overseer.files` modules are required by
-- cpp_parser.lua, so make sure they resolve too.
vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/lazy/overseer.nvim')

-- Make `require('srydell...')` and `require('overseer.template.srydell...')`
-- etc. resolve to this config's own lua/ directory (this repo's
-- lua/overseer/... only adds to overseer.nvim's namespace, it doesn't
-- replace it).
vim.opt.runtimepath:append(vim.fn.getcwd())

require('plenary.busted')
