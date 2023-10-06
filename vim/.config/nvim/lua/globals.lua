-- Check current operating system
-- Linux for Linux
-- Darwin for MacOS
if ( vim.g.currentOS == nil )
then
  vim.g.currentOS = io.popen('uname'):read()
  if ( vim.g.currentOS == 'Darwin' )
  then
    vim.g.browser = 'Safari'
  else
    vim.g.browser = 'firefox-developer-edition'
  end
end

-- Always use filetype latex for .tex files
vim.g.tex_flavor = 'latex'

-- Use default bindings for vimspector
vim.g.vimspector_enable_mappings = 'HUMAN'

-- Send to tmux when using slime
vim.g.slime_target = 'tmux'
vim.g.slime_default_config = {socket_name = 'default', target_pane = '{right-of}'}
vim.g.slime_dont_ask_default = 1
vim.g.slime_no_mappings = 1

vim.g.maximizer_set_default_mapping = 0
