local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local lspconfig = require('lspconfig')

-- Enable some language servers with the additional completion capabilities offered by nvim-cmp
local servers = { 'clangd', 'pyright', 'lua_ls' }
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup({
    -- on_attach = my_custom_on_attach,
    capabilities = capabilities,
  })
end

-- example to setup lua_ls and enable call snippets
lspconfig['lua_ls'].setup({
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace"
      }
    }
  }
})
