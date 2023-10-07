-- Encoding
--
vim.opt.encoding = 'utf-8'

-- Make it easier to see tabs, newlines, and trailing spaces
vim.opt.list = true
vim.opt.listchars = { tab =  '▸ ', eol =  '¬', trail = '·' }

-- BOX DRAWINGS HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
-- MIDDLE DOT (U+00B7, UTF-8: C2 B7)
-- Draw the vertical border between vim splits as a continuous line
-- Draw the character used to fill out the fold
vim.opt.fillchars = { vert = '┃', fold = '·'}

-- Not as cool as syntax, but faster
vim.opt.foldmethod = 'indent'

-- Start unfolded
vim.opt.foldlevelstart = 99
-- vim.opt.foldtext = folding#FoldText()

-- Show absolute current row and relative rows from that
vim.opt.number = true
vim.opt.relativenumber = true

-- Make backspace be able to delete indent and before starting position
vim.opt.backspace = { 'indent', 'eol', 'start' }

-- Keep the cursor in the middle of the screen
vim.opt.scrolloff = 999

-- Cursor visuals.     Block                  ,  Underscore
vim.opt.guicursor = { 'n-v-c-sm-i-ci-ve:block', 'r-cr-o:hor20' }

-- Show commands as they are being written
vim.opt.showcmd = true

-- Do not show the current mode (insert, visual, ...)
vim.opt.showmode = false

-- Softwrap text (without creating a newline)
vim.opt.wrap = true

-- Make vim highlight search while typing
vim.opt.incsearch = true

-- Auto read file when changed while open
vim.opt.autoread = true

-- Auto write on :make
vim.opt.autowrite = true

-- Autoindent new lines to match previous line
-- Autoindent when creating new lines
vim.opt.autoindent = true

-- Make vim exit visual mode without delay
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0

-- Don't redraw buffer while evaluating macros
vim.opt.lazyredraw = true

-- Be able to hide unsaved buffers while editing new ones
vim.opt.hidden = true

-- Ignore case if search is lowercase, otherwise case-sensitive
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Allow the visual block to not be restricted by EOL
vim.opt.virtualedit = 'block'

-- Disable error feedback via flashing screen
vim.opt.visualbell = false

-- Default to splitting below and to the right with :split :vsplit
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Better autocomplete
vim.opt.completeopt = { 'longest', 'menuone', 'noselect', 'preview' }

-- Maximum number of autocomplete items
vim.opt.pumheight = 6

-- Completion with commands
vim.opt.wildmenu = true
vim.opt.wildmode = {'longest', 'full'}

-- Ignore the following
vim.opt.wildignore = {
  '*.o', '*.a', '*.aux',
  '*.out', '*.toc', '__pycache__',
  '.git', '*.sw?', '*.DS_Store',
  '*.pyc', '*.jpg', '*.bmp',
  '*.jpeg', '*.gif', '*.png'
}

-- Let vim store backup/swap/undo files in these directories
-- The double // will create files with whole path expanded.
vim.opt.backupdir = os.getenv('HOME') .. '/.config/nvim/tmp/backup//'
vim.opt.directory = os.getenv('HOME') .. '/.config/nvim/tmp/swap//'
vim.opt.undodir = os.getenv('HOME') .. '/.config/nvim/tmp/undo//'


-- Delete old backup, backup current file
vim.opt.backup = true
vim.opt.writebackup = true

-- Persistent undo tree after exiting vim
vim.opt.undofile = true

-- How many levels are saved in each file
vim.opt.undolevels = 100

-- Better display for messages
vim.opt.cmdheight = 2

-- For faster diagnostics
vim.opt.updatetime = 300

-- Don't give |ins-completion-menu| messages.
vim.opt.shortmess:append('c')

-- Always show signcolumns
vim.opt.signcolumn = 'yes'

-- Use sh. It's faster than bash
vim.opt.shell = 'sh'

-- Do not highlight searched terms
vim.opt.hlsearch = false
