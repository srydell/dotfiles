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

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local lspconfig = require('lspconfig')

local on_attach = function(_, _) end

vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {})
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})

vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, {})
-- vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, {})
vim.keymap.set('n', 'gr', vim.lsp.buf.references, {})
vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})

for _, lsp in ipairs(constants.lsp_servers) do
  lspconfig[lsp].setup({
    -- on_attach = my_custom_on_attach,
    capabilities = capabilities,
    on_attach = on_attach,
  })
end

-- setup lua_ls and enable call snippets
lspconfig['lua_ls'].setup({
  settings = {
    Lua = {
      completion = {
        callSnippet = 'Replace',
      },
    },
  },
})
