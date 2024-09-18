local home = os.getenv('HOME')
for option, value in pairs({
  encoding = 'utf-8',

  -- Make it easier to see tabs, newlines, and trailing spaces
  list = true,
  listchars = { tab = '▸ ', eol = '¬', trail = '·' },

  -- BOX DRAWINGS HEAVY VERTICAL (U+2503, UTF-8: E2 94 83)
  -- MIDDLE DOT (U+00B7, UTF-8: C2 B7)
  -- Draw the vertical border between vim splits as a continuous line
  -- Draw the character used to fill out the fold
  fillchars = { vert = '┃', fold = '·' },

  -- Not as cool as syntax, but faster
  foldmethod = 'indent',

  -- Start unfolded
  foldlevelstart = 99,
  -- foldtext = folding#FoldText()

  -- Show absolute current row
  number = true,
  relativenumber = false,

  -- Make backspace be able to delete indent and before starting position
  backspace = { 'indent', 'eol', 'start' },

  -- Keep the cursor in the middle of the screen
  scrolloff = 999,

  -- Cursor visuals.     Block                  ,  Underscore
  guicursor = { 'n-v-c-sm-i-ci-ve:block', 'r-cr-o:hor20' },

  -- Show commands as they are being written
  showcmd = true,

  -- Do not show the current mode (insert, visual, ...)
  showmode = false,

  -- Softwrap text (without creating a newline)
  wrap = true,

  -- Make vim highlight search while typing
  incsearch = true,

  -- Auto read file when changed while open
  autoread = true,

  -- Auto write on :make
  autowrite = true,

  -- Make vim exit visual mode without delay
  timeoutlen = 1000,
  ttimeoutlen = 0,

  -- Don't redraw buffer while evaluating macros
  lazyredraw = true,

  -- Be able to hide unsaved buffers while editing new ones
  hidden = true,

  -- Ignore case if search is lowercase, otherwise case-sensitive
  ignorecase = true,
  smartcase = true,

  -- Allow the visual block to not be restricted by EOL
  virtualedit = 'block',

  -- Disable error feedback via flashing screen
  visualbell = false,

  -- Default to splitting below and to the right with :split :vsplit
  splitbelow = true,
  splitright = true,

  -- Better autocomplete
  completeopt = { 'longest', 'menuone', 'noselect', 'preview' },

  -- Maximum number of autocomplete items
  pumheight = 6,
  previewheight = 6,

  -- Completion with commands
  wildmenu = true,
  wildmode = { 'longest', 'full' },

  -- Ignore the following
  wildignore = {
    '*.o',
    '*.a',
    '*.aux',
    '*.out',
    '*.toc',
    '__pycache__',
    '.git',
    '*.sw?',
    '*.DS_Store',
    '*.pyc',
    '*.jpg',
    '*.bmp',
    '*.jpeg',
    '*.gif',
    '*.png',
  },

  -- Let vim store backup/swap/undo files in these directories
  -- The double // will create files with whole path expanded.
  backupdir = home .. '/.config/nvim/tmp/backup//',
  directory = home .. '/.config/nvim/tmp/swap//',
  undodir = home .. '/.config/nvim/tmp/undo//',

  -- Delete old backup, backup current file
  backup = true,
  writebackup = true,

  -- Persistent undo tree after exiting vim
  undofile = true,

  -- How many levels are saved in each file
  undolevels = 100,

  -- Better display for messages
  cmdheight = 2,

  -- For faster diagnostics
  updatetime = 300,

  -- Always show signcolumns
  signcolumn = 'yes',

  -- Use sh. It's faster than bash
  shell = 'sh',

  -- Do not highlight searched terms
  hlsearch = false,
}) do
  vim.opt[option] = value
end

-- Don't give |ins-completion-menu| messages.
vim.opt.shortmess:append('c')
