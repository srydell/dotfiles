local M = {}

function M.is_enabled(module, lang, _bufnr)
  if module ~= 'highlight' then
    return false
  end

  local ok = pcall(vim.treesitter.language.add, lang)
  if not ok then
    return false
  end

  local parser = vim.treesitter.get_parser(_bufnr, lang, { error = false })
  return parser ~= nil
end

function M.get_module(module)
  if module == 'highlight' then
    return {
      additional_vim_regex_highlighting = false,
    }
  end

  return {}
end

function M.setup(_)
  -- Compatibility shim for plugins that still expect the old
  -- nvim-treesitter.configs module to exist.
end

return M
