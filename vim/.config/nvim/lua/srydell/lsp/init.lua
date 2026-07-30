local is_headless = #vim.api.nvim_list_uis() == 0

if not is_headless then
  require('mason').setup({
    pip = {
      install_args = {
        '--trusted-host',
        'pypi.org',
        '--trusted-host',
        'pypi.python.org',
        '--trusted-host',
        'files.pythonhosted.org',
      },
    },
  })
end

local lsp_servers = {
  'bashls',
  'clangd',
  'helm_ls',
  'jdtls',
  'lua_ls',
  'marksman',
  'neocmake',
  'pylsp',
  'texlab',
  'yamlls',
  'kotlin_language_server',
  'harper_ls',
  -- 'elixirls',
  -- 'perlnavigator',
  -- 'ruby-lsp',
}

if not is_headless then
  local mason_lspconfig = require('mason-lspconfig')
  mason_lspconfig.setup({
    automatic_enable = true,
    ensure_installed = lsp_servers,
    exclude = {
      'jdtls', -- conflicts with nvim-jdtls
    },
  })

  require('mason-tool-installer').setup({
    -- a list of all tools you want to ensure are installed upon
    -- start; they should be the names Mason uses for each tool
    ensure_installed = {
      -- Debug servers
      'codelldb',
      'debugpy',
      'bash-debug-adapter',

      -- Formatters
      'ruff',
      'isort',
      'black',
      'shellcheck',
      'stylua',
    },
    run_on_start = false,
  })
end

local lsp_util = require('lspconfig.util')
local capabilities = require('blink.cmp').get_lsp_capabilities()

local on_attach = function(_, bufnr)
  local opts = { buffer = bufnr, silent = true }

  -- opts.desc = 'Show line diagnostics'
  -- vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)

  opts.desc = 'Rename declarator'
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  opts.desc = 'Apply code action'
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)

  opts.desc = 'Go to definition'
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  opts.desc = 'Go to implementation'
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  opts.desc = 'Show references for declarator under cursor'
  vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, opts)
  -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  opts.desc = 'Show documentation for what is under cursor'
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
end

vim.lsp.config('*', {
  capabilities = capabilities,
  on_attach = on_attach,
})

vim.lsp.config('clangd', {
  root_dir = function(bufnr, on_dir)
    -- Pick the nearest marker regardless of its name. This prevents a parent
    -- ~/.clangd directory from outranking a project's compilation database.
    local marker = vim.fs.find({
      '.clangd',
      '.clang-tidy',
      '.clang-format',
      'compile_commands.json',
      'compile_flags.txt',
      'configure.ac',
      '.git',
    }, {
      path = vim.api.nvim_buf_get_name(bufnr),
      upward = true,
      limit = 1,
    })[1]
    if marker then
      on_dir(vim.fs.dirname(marker))
    end
  end,
})

-- Setup harper_ls and configure it to only use markdown files
vim.lsp.config('harper_ls', {
  filetypes = { 'markdown' },
})

local function sourcekit_root_dir(bufnr, on_dir)
  local filename = vim.api.nvim_buf_get_name(bufnr)
  local git_dir = vim.fs.find('.git', { path = filename, upward = true })[1]

  local root_dir = lsp_util.root_pattern('buildServer.json')(filename)
    or lsp_util.root_pattern('*.xcodeproj', '*.xcworkspace')(filename)
    or lsp_util.root_pattern('Package.swift')(filename)
    or (git_dir and vim.fs.dirname(git_dir) or nil)

  if root_dir then
    on_dir(root_dir)
  end
end

local sourcekit_cmd
if vim.fn.executable('sourcekit-lsp') == 1 then
  sourcekit_cmd = { vim.fn.exepath('sourcekit-lsp') }
elseif vim.fn.has('mac') == 1 and vim.fn.executable('xcrun') == 1 then
  sourcekit_cmd = { 'xcrun', 'sourcekit-lsp' }
end

if sourcekit_cmd then
  vim.lsp.config('sourcekit', {
    capabilities = vim.tbl_deep_extend('force', capabilities, {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true,
        },
      },
    }),
    cmd = sourcekit_cmd,
    filetypes = { 'swift' },
    root_dir = sourcekit_root_dir,
  })
  vim.lsp.enable('sourcekit')
end
