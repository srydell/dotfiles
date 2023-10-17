-- ---- Leader mappings ----
-- <leader><lowerCaseLetter> for harmless commands
-- <leader><upperCaseLetter> for potentially harmful commands

-- Open buffer and edit
vim.keymap.set('n', '<leader>ev', ':VimNOut edit ~/.config/nvim/init.lua<CR>')
vim.keymap.set('n', '<leader>et', ':VimNOut edit ~/.tmux.conf<CR>')
vim.keymap.set('n', '<leader>ep', ':VimNOut edit ~/.config/nvim/plugin/projectionist.vim<CR>')
vim.keymap.set('n', '<leader>ex', ':VimNOut edit ~/.config/nvim/ftplugin/{filetype}/{files}<CR>')

vim.keymap.set('n', '<leader>es', ':VimNOut edit ~/.config/nvim/snips/{filetype}.lua<CR>')
vim.keymap.set('n', '<leader>eas', ':VimNOut edit ~/.config/nvim/luasnip/all.lua<CR>')
vim.keymap.set('n', '<leader>ef', ':VimNOut edit ~/.config/nvim/ftplugin/{filetype}.vim<CR>')
vim.keymap.set('n', '<leader>eaf', ':VimNOut edit ~/.config/nvim/after/ftplugin/{filetype}.vim<CR>')
vim.keymap.set('n', '<leader>eef', ':VimNOut edit ~/.config/nvim/autoload/extra_filetypes/{filetype}.vim<CR>')

-- Compiler
vim.keymap.set('n', '<leader>ec', ':VimNOut edit ~/.config/nvim/compiler/{compiler}.vim<CR>')
vim.keymap.set('n', '<leader>ecs', ':VimNOut edit ~/.config/nvim/integrations/compiler/{files}<CR>')
vim.keymap.set('n', '<leader>eac', ':VimNOut edit ~/.config/nvim/compiler/{files}<CR>')

-- Fuzzy finder - fzf (files)
vim.keymap.set('n', '<leader>ff', ':<C-u>FZF<CR>')

-- Find all the TODO/FIXME in current git project
-- :Todo command specified in .vim/plugin/searchtools.vim
vim.keymap.set('n', '<leader>ft', ':Todo<CR>')

vim.keymap.set('n', '<leader>fz', ':MaximizerToggle<CR>')

-- Search for the current word in the whole directory structure
vim.keymap.set('n', '<leader>*', ':Grepper -cword -noprompt<CR>')

-- Search for the current selection
-- nmap <leader>gs <Plug>(GrepperOperator)
-- xmap <leader>gs <Plug>(GrepperOperator)

-- Search for the current word in the whole directory structure
vim.keymap.set('n', '<leader>/', ':Grepper<CR>')

-- function! GitAddCommitPush() abort
--   wa
--   Git add -u
--   Git commit --verbose
-- endfunction

-- Run git add -u
vim.keymap.set('n', '<leader>gz', ':call GitAddCommitPush()<CR>')

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
-- Takes a browser and OS
vim.keymap.set('n', '<leader>h', ':call helpDocs#GetHelpDocs(g:browser, g:currentOS)<CR>', { silent = true })

-- Prompt for a command to run in the nearest tmux pane ( [t]mux [c]ommand )
vim.keymap.set('n', '<leader>tc', ':VimuxPromptCommand<CR>', { silent = true })

-- Run last command executed by VimuxRunCommand ( [t]mux [r]un )
vim.keymap.set('n', '<leader>tr', ':call tmux#VimuxRunLastCommandIfExists()<CR>', { silent = true })

-- Inspect runner pane ( [t]mux [i]nspect )
vim.keymap.set('n', '<leader>ti', ':VimuxInspectRunner<CR>', { silent = true })

-- Zoom the tmux runner pane ( [t]mux [f]ullscreen )
vim.keymap.set('n', '<leader>tf', ':VimuxZoomRunner<CR>', { silent = true })

-- vim.keymap.set('n', 'm<space>', ':AsyncRun -program=make', { silent = true })
-- vim.keymap.set('n', 'm<CR>', ':AsyncRun -program=make<CR>', { silent = true })
vim.keymap.set('n', 'm<space>', ':make', { silent = true })
vim.keymap.set('n', 'm<CR>', ':make<CR>', { silent = true })

-- Move through the buffer list
vim.keymap.set('n', '[b', ':bprevious<CR>', { silent = true })
vim.keymap.set('n', ']b', ':bnext<CR>', { silent = true })
vim.keymap.set('n', '[B', ':bfirst<CR>', { silent = true })
vim.keymap.set('n', ']B', ':blast<CR>', { silent = true })

-- How I think about alternative files
vim.keymap.set('n', '[a', ':A<CR>', { silent = true })
vim.keymap.set('n', ']a', ':A<CR>', { silent = true })

-- Move through the valid compilers. Set by b:valid_compilers
vim.keymap.set('n', ']c', ':CompilerNext<CR>', { silent = true })
vim.keymap.set('n', '[c', ':CompilerPrevious<CR>', { silent = true })

-- Move through the loclist
vim.keymap.set('n', '<leader>l', ':call utils#ToggleList("Location List", "l")<CR>', { silent = true })
vim.keymap.set('n', '[l', ':lprevious<CR>', { silent = true })
vim.keymap.set('n', ']l', ':lnext<CR>', { silent = true })
vim.keymap.set('n', '[L', ':lfirst<CR>', { silent = true })
vim.keymap.set('n', ']L', ':llast<CR>', { silent = true })

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

-- Fast substitutions for
-- Word under the cursor in normal mode
-- Visual selection in visual mode (Also copies selection into ")
-- <leader>su for the current paragraph
-- <leader>S for the whole file
-- vim.keymap.set('n', '<leader>su', ':' .. ''' .. '{,' .. ''' .. '}s/\<<C-r><C-w>\>//g<left><left>')
-- vim.keymap.set('n', '<leader>su', ':'{,'}s/\<<C-r><C-w>\>//g<left><left>')
-- xnoremap <leader>su y:'{,'}s/<C-r><C-0>//g<left><left>
-- vim.keymap.set('n', '<leader>S', ':%s/\<<C-r><C-w>\>//g<left><left>')
-- xnoremap <leader>S y:%s/<C-r><C-0>//g<left><left>

-- Write document
vim.keymap.set('n', '<leader>w', ':write<CR>')

-- Write all buffers and exit
-- If there are buffers without a name,
-- or that are readonly, bring up a confirm prompt
vim.keymap.set('n', '<leader>W', ':confirm wqall<CR>')

-- Unfold all folds under cursor
-- vim.keymap.set('n', '<leader><Space> za
-- Create fold for visually selected text
-- vnoremap <leader><Space> zf

-- Normally zj/zk moves to folds even if they are open
vim.keymap.set('n', '<leader>zj', ':call folding#NextClosedFold("j")<cr>', { silent = true })
vim.keymap.set('n', '<leader>zk', ':call folding#NextClosedFold("k")<cr>', { silent = true })

-- Zoom a vim pane, <C-w>= to re-balance
vim.keymap.set('n', '<leader>-', ':wincmd _<cr>:wincmd \\|<cr>', { silent = true })
vim.keymap.set('n', '<leader>=', ':wincmd =<cr>', { silent = true })

-- Send to tmux pane
vim.keymap.set('n', 'gs', '<Plug>SlimeMotionSend', {remap = true})
vim.keymap.set('n', 'gss', '<Plug>SlimeLineSend', {remap = true})
vim.keymap.set('x', 'gs', '<Plug>SlimeRegionSend', {remap = true})

-- H moves to beginning of line and L to end of line
vim.keymap.set('n', 'H', '^')
vim.keymap.set('n', 'L', '$')

-- Make cursor still while joining lines. Using mark z
vim.keymap.set('n', 'J', 'mzJ`z')

-- Let vim treat virtual lines as real lines
-- v:count works better with relativenumber
vim.keymap.set('n', '<expr>', 'j v:count ? "j" : "gj"')
vim.keymap.set('n', '<expr>', 'k v:count ? "k" : "gk"')
vim.keymap.set('n', 'gj', 'j')
vim.keymap.set('n', 'gk', 'k')

-- Make Y more consistent with C and D
vim.keymap.set('n', 'Y', 'y$')
