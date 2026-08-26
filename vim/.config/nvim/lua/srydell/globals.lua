-- Disable unused remote-plugin providers. Neovim otherwise spawns python3/perl/ruby/node
-- to probe for pynvim/neovim host support on things like `has('python3')` (e.g. triggered
-- by the built-in python ftplugin), which is expensive (~350ms) and unused since no plugin
-- here relies on these remote-plugin hosts (LSP/completion is handled without them).
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- Always use filetype latex for .tex files
vim.g.tex_flavor = 'latex'

-- Use default bindings for vimspector
vim.g.vimspector_enable_mappings = 'HUMAN'

-- Send to tmux when using slime
vim.g.slime_target = 'tmux'
vim.g.slime_default_config = { socket_name = 'default', target_pane = '{right-of}' }
vim.g.slime_dont_ask_default = 1
vim.g.slime_no_mappings = 1

vim.g.maximizer_set_default_mapping = 0
