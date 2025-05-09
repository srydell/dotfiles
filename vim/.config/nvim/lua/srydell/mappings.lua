-- ---- Leader mappings ----
-- <leader><lowerCaseLetter> for harmless commands
-- <leader><upperCaseLetter> for potentially harmful commands

local builtin = require('telescope.builtin')

local function find_neovim_files()
  builtin.find_files({
    cwd = vim.fn.stdpath('config'),
  })
end

-- Open buffer and edit
vim.keymap.set('n', '<leader>ev', find_neovim_files, { silent = true })
vim.keymap.set('n', '<leader>et', ':VimNOut edit ~/.tmux.conf<CR>', { silent = true })
vim.keymap.set('n', '<leader>ep', ':VimNOut edit ~/.config/nvim/plugin/projectionist.lua<CR>', { silent = true })

vim.keymap.set('n', '<leader>es', ':VimNOut edit ~/.config/nvim/snips/{filetype}.lua<CR>', { silent = true })
vim.keymap.set(
  'n',
  '<leader>eas',
  ':VimNOut edit ~/.config/nvim/lua/srydell/snips/skeleton/{filetype}.lua<CR>',
  { silent = true }
)
vim.keymap.set('n', '<leader>em', ':VimNOut edit ~/.config/nvim/lua/srydell/mappings.lua<CR>', { silent = true })
vim.keymap.set('n', '<leader>ef', ':VimNOut edit ~/.config/nvim/ftplugin/{filetype}.lua<CR>', { silent = true })
vim.keymap.set('n', '<leader>eaf', ':VimNOut edit ~/.config/nvim/after/ftplugin/{filetype}.lua<CR>', { silent = true })

-- Fuzzy finder
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fz', builtin.current_buffer_fuzzy_find, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>/', builtin.live_grep, {})
vim.keymap.set('n', '<leader>*', builtin.grep_string, {})

-- Run git add -u
vim.keymap.set('n', '<leader>gb', ':Git blame<CR>', { silent = true })

-- Run git add -u
vim.keymap.set('n', '<leader>gu', ':Git add -u<CR>')

-- Add file corresponding to current buffer
vim.keymap.set('n', '<leader>ga', ':Gwrite<CR>')

-- Open commit message in a new buffer
-- --verbose so that the changes are visible
--  while in the commit message
vim.keymap.set('n', '<leader>gc', ':Git commit --verbose<CR>')

-- Push the changes
vim.keymap.set('n', '<leader>gp', ':Git push origin HEAD<CR>')

-- Revert current file to last checked in version
-- Same as running :!git checkout %
vim.keymap.set('n', '<leader>Gr', ':Gread<CR>')

-- Open appropriate help on the word under the cursor
-- Filetype dependent.
-- Takes a browser
vim.keymap.set('n', '<leader>h', ':call helpDocs#GetHelpDocs()<CR>', { silent = true })

-- Prompt for a command to run in the nearest tmux pane ( [t]mux [c]ommand )
vim.keymap.set('n', '<leader>tc', ':VimuxPromptCommand<CR>', { silent = true })

-- Run last command executed by VimuxRunCommand ( [t]mux [r]un )
vim.keymap.set('n', '<leader>tr', ':call tmux#VimuxRunLastCommandIfExists()<CR>', { silent = true })

-- Inspect runner pane ( [t]mux [i]nspect )
vim.keymap.set('n', '<leader>ti', ':VimuxInspectRunner<CR>', { silent = true })

-- Zoom the tmux runner pane ( [t]mux [f]ullscreen )
vim.keymap.set('n', '<leader>tf', ':VimuxZoomRunner<CR>', { silent = true })

vim.keymap.set('n', 'm<CR>', require('srydell.compiler.common').run, { silent = true })
vim.keymap.set('n', '<leader>ec', require('srydell.compiler.common').edit_compiler_option, { silent = true })

-- Move through the valid compilers. Set by b:valid_compilers
vim.keymap.set('n', ']c', require('srydell.compiler.common').go_to_next_compiler, { silent = true })
vim.keymap.set('n', '[c', require('srydell.compiler.common').go_to_previous_compiler, { silent = true })

-- Move through the buffer list
vim.keymap.set('n', '[b', ':bprevious<CR>', { silent = true })
vim.keymap.set('n', ']b', ':bnext<CR>', { silent = true })
vim.keymap.set('n', '[B', ':bfirst<CR>', { silent = true })
vim.keymap.set('n', ']B', ':blast<CR>', { silent = true })

-- Alternative files
vim.keymap.set('n', '[a', ':A<CR>', { silent = true })
vim.keymap.set('n', ']a', ':A<CR>', { silent = true })

-- Move through the loclist
vim.keymap.set('n', '<leader>l', ':call utils#ToggleList("Location List", "l")<CR>', { silent = true })
vim.keymap.set('n', '[l', ':lprevious<CR>', { silent = true })
vim.keymap.set('n', ']l', ':lnext<CR>', { silent = true })
vim.keymap.set('n', '[L', ':lfirst<CR>', { silent = true })
vim.keymap.set('n', ']L', ':llast<CR>', { silent = true })
vim.keymap.set('n', '<leader>dl', vim.diagnostic.setloclist, { desc = 'Add buffer diagnostics to the location list.' })

-- Move through the quickfix list
vim.keymap.set('n', '<leader>q', ':call utils#ToggleList("Quickfix List", "c")<CR>', { silent = true })
vim.keymap.set('n', '[q', ':cprevious<CR>', { silent = true })
vim.keymap.set('n', ']q', ':cnext<CR>', { silent = true })
vim.keymap.set('n', '[Q', ':cfirst<CR>', { silent = true })
vim.keymap.set('n', ']Q', ':clast<CR>', { silent = true })

-- Keep selection while indenting
vim.keymap.set('v', '>', '><cr>gv', { silent = true })
vim.keymap.set('v', '<', '<<cr>gv', { silent = true })

-- Yank to system clipboard
vim.keymap.set('n', '<leader>y', '"*y')
vim.keymap.set('x', '<leader>y', '"*ygv<Esc>')

-- Paste from clipboard
vim.keymap.set('n', '<leader>p', ':setlocal paste<CR>"*p<CR>:setlocal nopaste<CR>', { silent = true })
vim.keymap.set('n', '<leader>P', ':setlocal paste<CR>"*P<CR>:setlocal nopaste<CR>', { silent = true })

-- Source vimrc
vim.keymap.set('n', '<leader>sv', ':source $MYVIMRC<CR>')

-- Write document
vim.keymap.set('n', '<leader>w', ':write<CR>')

-- Write all buffers and exit
-- If there are buffers without a name,
-- or that are readonly, bring up a confirm prompt
vim.keymap.set('n', '<leader>W', ':confirm wqall<CR>')

-- Normally zj/zk moves to folds even if they are open
vim.keymap.set('n', '<leader>zj', ':call folding#NextClosedFold("j")<cr>', { silent = true })
vim.keymap.set('n', '<leader>zk', ':call folding#NextClosedFold("k")<cr>', { silent = true })

-- Zoom a vim pane, <C-w>= to re-balance
vim.keymap.set('n', '<leader>-', ':wincmd _<cr>:wincmd \\|<cr>', { silent = true })
vim.keymap.set('n', '<leader>=', ':wincmd =<cr>', { silent = true })

-- Send to tmux pane
vim.keymap.set('n', 'gs', '<Plug>SlimeMotionSend', { remap = true })
vim.keymap.set('n', 'gss', '<Plug>SlimeLineSend', { remap = true })
vim.keymap.set('x', 'gs', '<Plug>SlimeRegionSend', { remap = true })

-- H moves to beginning of line and L to end of line
vim.keymap.set('n', 'H', '^')
vim.keymap.set('n', 'L', '$')

-- Make cursor still while joining lines. Using mark z
vim.keymap.set('n', 'J', 'mzJ`z')

-- Let vim treat virtual lines like real lines
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set('n', 'gj', 'j')
vim.keymap.set('n', 'gk', 'k')

-- Make Y more consistent with C and D
vim.keymap.set('n', 'Y', 'y$')
