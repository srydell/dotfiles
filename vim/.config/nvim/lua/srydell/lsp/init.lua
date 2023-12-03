local constants = require('srydell.constants')

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

require('mason-lspconfig').setup()

require('mason-tool-installer').setup({
  -- a list of all tools you want to ensure are installed upon
  -- start; they should be the names Mason uses for each tool
  ensure_installed = constants.tools,
})

local lspconfig = require('lspconfig')
local util = require('lspconfig.util')
local cmp_nvim_lsp = require('cmp_nvim_lsp')
local capabilities = cmp_nvim_lsp.default_capabilities()

local opts = { noremap = true, silent = true }
local on_attach = function(_, bufnr)
  opts.buffer = bufnr

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

for _, lsp in ipairs(constants.lsp_servers) do
  lspconfig[lsp].setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })
end

-- setup sourcekit
lspconfig['sourcekit'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  cmd = {
    '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/sourcekit-lsp',
  },
  root_dir = function(filename, _)
    return util.root_pattern('buildServer.json')(filename)
      or util.root_pattern('*.xcodeproj', '*.xcworkspace')(filename)
      or util.find_git_ancestor(filename)
      or util.root_pattern('Package.swift')(filename)
  end,
})

-- setup lua_ls and enable call snippets
lspconfig['lua_ls'].setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      completion = {
        callSnippet = 'Replace',
      },
    },
  },
})
